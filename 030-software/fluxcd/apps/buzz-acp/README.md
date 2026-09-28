# buzz-acp

Bridge between the Buzz relay and the KubeOpenCode `main` agent: mention the agent in the
Buzz app, it answers with OpenCode.

```
Buzz app ──wss──▶ buzz relay ──ws──▶ buzz-acp ──ACP/stdio──▶ opencode acp ──▶ model
```

`buzz-acp` is the upstream harness from [block/buzz](https://github.com/block/buzz) (same
component the [mager.co write-up](https://www.mager.co/blog/2026-08-08-opencode-go-buzz-harness)
and the [Akash deployment](https://github.com/Swpn0neel/awesome-akash-bifrost-20260916/blob/master/Buzz-OpenCode-Agent/README.md)
use). The relay image does not ship it, so the `Dockerfile` in this directory builds it from
source and the `buzz-acp-image` workflow pushes `ghcr.io/shokohsc/buzz-acp`.

The agent it spawns is the same OpenCode build, model, skills, instructions and read-only
cluster access as the `main` agent in `../kubeopencode`, so a Buzz conversation behaves like
a Task conversation. It is a separate process with its own session: it does not see, and is not
seen by, the long lived `main-server` OpenCode process.

## Layout

| File | What |
| --- | --- |
| `deployment.yaml` | The bridge. Two init containers (OpenCode binary, homelab checkout for the skills) then `buzz-acp` itself. |
| `secret.yaml` | Agent Nostr identity. **Plaintext placeholder, encrypt before merging** (see below). |
| `config/opencode.json` | Model and skill paths, mirrors the main agent. |
| `config/context.md` | Agent instructions: homelab/GitOps rules and how to answer on a phone. |
| `Dockerfile` | `buzz-acp` + `buzz` CLI on top of the KubeOpenCode devbox image. |

Tuning knobs are environment variables in `deployment.yaml`: `BUZZ_ACP_SUBSCRIBE`
(`mentions` or `all`), `BUZZ_ACP_RESPOND_TO` (`owner-only`, `allowlist`, `anyone`),
`BUZZ_ACP_AGENTS` (concurrent sessions, default 1), `BUZZ_ACP_AGENT_OWNER`.
Every flag of `buzz-acp` has an env var, see `buzz-acp --help`.

## Setup

1. Build the image. The workflow runs on every push that touches the `Dockerfile` or the
   workflow itself, or dispatch `buzz-acp-image` manually. The deployment pulls `:latest`,
   so it stays crash-looping on `ImagePullBackOff` until the first build finishes. The
   package has to be public (or `imagePullSecrets` added), the cluster pulls anonymously.

2. Mint an identity for the agent. The relay image contains `buzz-admin`, and `kubectl exec`
   inherits the relay container environment (relay signing key, database, redis):

   ```sh
   kubectl -n buzz exec deploy/relay -- buzz-admin generate-key
   ```

   Keep both halves. The public key becomes a relay member, the secret key goes into the
   secret below.

3. Let the agent through the relay (`BUZZ_REQUIRE_RELAY_MEMBERSHIP=true`):

   ```sh
   kubectl -n buzz exec deploy/relay -- buzz-admin add-member --pubkey <AGENT_PUBKEY>
   ```

4. Fill in `secret.yaml` and encrypt it. Flux decrypts with the `sops-gpg` key, the public key
   is in `030-software/fluxcd/core/.sops.pub.asc`:

   ```sh
   $EDITOR 030-software/fluxcd/apps/buzz-acp/secret.yaml
   sops --encrypt --in-place 030-software/fluxcd/apps/buzz-acp/secret.yaml
   ```

   - `BUZZ_PRIVATE_KEY`: the agent secret key from step 2.
   - `BUZZ_ACP_AGENT_OWNER`: your own 64 hex char pubkey, the only identity allowed to
     command the agent.

5. Wait for the pod, then give the agent a name so it shows up in the Buzz UI:

   ```sh
   kubectl -n workspace rollout status deploy/buzz-acp
   kubectl -n workspace logs -f deploy/buzz-acp
   kubectl -n workspace exec deploy/buzz-acp -- buzz users set-profile --name main --about "KubeOpenCode main agent"
   ```

6. Put the agent in a channel. Mentions are only delivered to channel members, so either add
   it from the app (channel, then members) or from the pod:

   ```sh
   kubectl -n workspace exec deploy/buzz-acp -- buzz channels add-member \
     --channel <CHANNEL> --pubkey <AGENT_PUBKEY> --role member
   ```

7. `@main` in the channel. The bridge only answers mentions of the agent, and only from its
   owner.

## Troubleshooting

| Symptom | Cause |
| --- | --- |
| `ImagePullBackOff` | The image has not been built yet, or `buzz-acp` is private to your account. |
| `unknown community` / `no community for host` | `BUZZ_RELAY_URL` must be the public gateway hostname. See below. |
| `invalid certificate` / TLS handshake fails | The `homelab-ca-cm` volume is missing from the pod. |
| No channel, nothing in the logs | The agent is not a relay member, step 3. |
| Answer arrives twice | Two bridges with the same key. `replicas: 1` and `strategy: Recreate` exist for that. |
| Nothing happens after a mention | Wrong display name in the mention, or the sender is not `BUZZ_ACP_AGENT_OWNER`. `buzz-acp` logs both. |

### Relay URL

`BUZZ_RELAY_URL` is `wss://relay.buzz.${domain}`, not `ws://relay.buzz.svc.cluster.local`. The
in cluster Service name looks more direct but the relay resolves the community from the
`Host` header and the community is created at boot from the relay's own `RELAY_URL`, so
`relay.buzz.svc.cluster.local` matches no community row and the connection is dropped. The
same value is what the relay checks in the NIP-42 `relay` tag and the NIP-98 `u` tag, so it
has to match character for character.

That means the websocket goes through the gateway, whose certificate is issued by the
homelab CA. `homelab-ca-cm` (default CAs plus the homelab root and intermediate, injected by
the cert-manager Bundle) is mounted and exported as `SSL_CERT_FILE`, which covers `reqwest`.
The websocket does not read `SSL_CERT_FILE`, it uses the root store compiled into the binary,
which is why the `Dockerfile` adds `rustls-tls-native-roots` to `tokio-tungstenite`.

## Limits

- One session per channel (`BUZZ_ACP_SESSION_POLICY`), lost when the pod restarts. No Task CRs
  are created, a Buzz turn is a conversation, not a job.
- A Buzz turn spawns its own `opencode acp` child per channel, so it does not share a session
  with the long lived `main-server` OpenCode. Same image, model, skills and context, different
  process.
- No plugins and no `anthropic-skills` here, unlike the `main` agent template. Add a
  `plugin-init` container if you want them.
- No liveness probe: `buzz-acp` exposes no port and there is nothing cheap to exec. If it
  wedges, restart the pod.
