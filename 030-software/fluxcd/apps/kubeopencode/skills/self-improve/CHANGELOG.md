## 2026-10-15

- learned-rules.md: added rule on handling secrets when the encryption key is unavailable.
  - What: placeholder secret manifests + the exact encrypt command instead of plaintext or stalling.
  - Why: a task required adding sops-encrypted secrets but the agent had no key and the repo was public.
  - Benefit: public repos stay leak-free and the change is still deliverable, with a clear hand-off.
## 2026-10-16

- learned-rules: OSS Loki and VictoriaMetrics only support time-based retention (no size cap); set retention to 1 week and size the PVC to fit.
## 2026-10-18

- learned-rules: `gh pr create` in CI containers needs explicit `--head`/`--base` even after a successful `git push -u`.
