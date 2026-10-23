import { execFile } from 'node:child_process'
import { mkdir, readFile, readdir, unlink, writeFile } from 'node:fs/promises'
import { createServer } from 'node:http'
import { extname, join } from 'node:path'

const dir = '/tmp/yamlresume'
const input = 'resume.yml'
const contentTypes = {
  '.pdf': 'application/pdf',
  '.html': 'text/html; charset=utf-8',
  '.md': 'text/markdown; charset=utf-8',
  '.tex': 'text/plain; charset=utf-8',
  '.docx':
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
  '.typ': 'text/plain; charset=utf-8',
}

let building = false

const run = (args) =>
  new Promise((resolve, reject) => {
    execFile(
      'yamlresume',
      args,
      {
        cwd: dir,
        env: { ...process.env, HOME: '/tmp' },
        maxBuffer: 10 * 1024 * 1024,
        timeout: 180000,
      },
      (error, stdout, stderr) =>
        error ? reject(new Error(stderr.trim() || error.message)) : resolve(stdout)
    )
  })

const readBody = (req) =>
  new Promise((resolve, reject) => {
    const chunks = []
    let size = 0
    req.on('data', (chunk) => {
      size += chunk.length
      if (size > 1024 * 1024) {
        reject(new Error('YAML is too large'))
        req.destroy()
      } else {
        chunks.push(chunk)
      }
    })
    req.on('end', () => resolve(Buffer.concat(chunks).toString('utf8')))
    req.on('error', reject)
  })

const escape = (value) =>
  value.replace(
    /[&<>"']/g,
    (char) =>
      ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' })[
        char
      ]
  )

const layout = (yaml, extra) => `<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>YAMLResume</title>
<style>
:root{color-scheme:dark}
*{box-sizing:border-box}
body{margin:0;font:14px/1.5 system-ui,sans-serif;background:#111827;color:#e5e7eb}
main{max-width:1100px;margin:0 auto;padding:1rem}
textarea{width:100%;height:40vh;padding:.75rem;border:1px solid #374151;border-radius:.5rem;background:#1f2937;color:inherit;font:13px/1.5 ui-monospace,monospace;resize:vertical}
button{padding:.5rem 1rem;border:0;border-radius:.5rem;background:#6366f1;color:#fff;font-weight:600;cursor:pointer}
a{color:#a5b4fc;margin-right:1rem}
pre{overflow:auto;padding:1rem;background:#1f2937;border-radius:.5rem}
iframe{width:100%;height:70vh;border:0;border-radius:.5rem;background:#fff;margin-top:1rem}
.bar{display:flex;gap:1rem;align-items:center;flex-wrap:wrap;margin-top:1rem}
</style>
</head>
<body>
<main>
<form method="post" action="/build">
<textarea name="yaml" spellcheck="false">${escape(yaml)}</textarea>
<div class="bar"><button>Build</button><span>Generates pdf, html and markdown from your YAML.</span></div>
</form>
${extra}
</main>
</body>
</html>`

const page = async (res, status, extra = '') => {
  let yaml = ''
  try {
    yaml = await readFile(join(dir, input), 'utf8')
  } catch {}
  res.writeHead(status, { 'content-type': 'text/html; charset=utf-8' })
  res.end(layout(yaml, extra))
}

const serveFile = async (res, name) => {
  if (!/^resume\.(pdf|html|md|tex|docx|typ)$/.test(name)) {
    res.writeHead(404)
    return res.end('not found')
  }
  let data
  try {
    data = await readFile(join(dir, name))
  } catch {
    res.writeHead(404)
    return res.end('not found')
  }
  res.writeHead(200, {
    'content-type': contentTypes[extname(name)] || 'application/octet-stream',
    'content-disposition': `inline; filename="${name}"`,
  })
  res.end(data)
}

const build = async (req, res) => {
  if (building) {
    return page(res, 429, '<pre>Another build is running, try again shortly.</pre>')
  }
  building = true
  try {
    const yaml = new URLSearchParams(await readBody(req)).get('yaml')
    if (!yaml?.trim()) {
      return page(res, 400, '<pre>Paste a resume YAML first.</pre>')
    }
    for (const file of await readdir(dir)) {
      if (file.startsWith('resume.') && file !== input) {
        await unlink(join(dir, file)).catch(() => {})
      }
    }
    await writeFile(join(dir, input), yaml)
    await run(['build', input])
    const files = (await readdir(dir))
      .filter((file) => file.startsWith('resume.') && file !== input)
      .sort()
    const links = files
      .map((file) => `<a href="/files/${file}" download>${file}</a>`)
      .join('')
    const preview = files.includes('resume.html')
      ? '<iframe src="/files/resume.html"></iframe>'
      : ''
    return page(res, 200, `<section><div class="bar">${links}</div>${preview}</section>`)
  } catch (error) {
    return page(res, 500, `<pre>${escape(String(error.message || error))}</pre>`)
  } finally {
    building = false
  }
}

await mkdir(dir, { recursive: true })
try {
  await readFile(join(dir, input))
} catch {
  await run(['new', input]).catch((error) =>
    console.error(`sample generation failed: ${error.message}`)
  )
}

createServer(async (req, res) => {
  try {
    const url = new URL(req.url, 'http://localhost')
    if (req.method === 'GET' && url.pathname === '/') return await page(res, 200)
    if (req.method === 'GET' && url.pathname === '/healthz') {
      res.writeHead(200, { 'content-type': 'text/plain' })
      return res.end('ok')
    }
    if (req.method === 'GET' && url.pathname.startsWith('/files/')) {
      return await serveFile(res, decodeURIComponent(url.pathname.slice(7)))
    }
    if (req.method === 'POST' && url.pathname === '/build') return await build(req, res)
    res.writeHead(404)
    res.end('not found')
  } catch (error) {
    res.writeHead(500, { 'content-type': 'text/plain' })
    res.end(String(error.message || error))
  }
}).listen(8080, '0.0.0.0')
