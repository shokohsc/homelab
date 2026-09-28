# nostr-gateway

Bridges [Nostr](https://github.com/nostr-protocol/nostr) to the KubeOpenCode
`main` agent. Messages arrive as Nostr events of kind `30078`, are NIP-44
encrypted to the agent's key, and are turned into an OpenCode session. Replies
are published back as encrypted events. There is also a small plain-HTTP API for
callers that are not on Nostr.

Source: <https://github.com/shokohsc/nostr-gateway>

## Image

`ghcr.io/shokohsc/nostr-gateway:9656caf` — the tag upstream CI publishes from
its main branch (`short=${GITHUB_SHA::7}`), so the reference is immutable. Bump
it, and this README's verification note, when upstream lands a new merge.

## Topology

- `main.workspace.svc.cluster.local:4096` is the KubeOpenCode server backing the
  `main` agent. `config/agents.json` points the gateway at it.
- The gateway itself is ClusterIP only. Nothing is exposed through the
  `cilium` Gateway, on purpose: Nostr is the public ingress and the HTTP API is
  an in-cluster convenience.
- `allow` in `config/agents.json` gates *Nostr* senders, not HTTP callers. It is
  matched against the pubkey that signed the event, so an event with a forged
  `sender` field does not get through. An empty list allows everyone — do not
  ship that.

## Before merging: two manual steps

1. Fill in the placeholders.
2. Encrypt the secret.

### 1. Generate the identity and the token

The gateway needs a Nostr keypair. Any Nostr key generator or `nostr` CLI
works; the gateway accepts hex, `nsec1...` and `npub1...` forms.

```sh
# in config/agents.json
#   npub   -> the public key of the identity whose secret goes in the Secret
#   allow  -> your own pubkey, so only you can drive the agent
```

```sh
openssl rand -hex 32   # -> GATEWAY_TOKEN in secret.yaml
```

Then edit:

- `config/agents.json`: replace `npub1REPLACE_ME` and `REPLACE_ME_HEX_PUBKEY`.
- `secret.yaml`: replace both `REPLACE_ME_*` values. `MAIN_NSEC` is the private
  key matching the `npub` above.

### 2. Encrypt the secret

The private key and the token must not be committed in plaintext.

```sh
sops --encrypt --in-place 030-software/fluxcd/apps/nostr-gateway/secret.yaml
```

This uses the repo's `.sops.yaml` and the operator's own PGP key, the same way
every other app secret in this repository is handled. Flux decrypts it on
reconcile because the `apps` Kustomization enables sops decryption.

## Verifying after deploy

```sh
kubectl -n nostr-gateway logs deploy/nostr-gateway
```

A healthy start logs the relays it connected to. Then, from inside the cluster:

```sh
TOKEN=$(kubectl -n nostr-gateway get secret nostr-gateway \
  -o jsonpath='{.data.GATEWAY_TOKEN}' | base64 -d)

curl -H "Authorization: Bearer $TOKEN" \
  -d '{"agent":"main","type":"message","payload":{"text":"say hi"}}' \
  http://nostr-gateway.nostr-gateway.svc.cluster.local/v1/messages

# the reply is a JSON envelope; take its conversation id and stream it
curl -H "Authorization: Bearer $TOKEN" \
  http://nostr-gateway.nostr-gateway.svc.cluster.local/v1/conversations/<id>/events
```

`GET /healthz` is unauthenticated and is what the probes use.

## Notes

- Conversations live in memory only, and the deployment is `Recreate` with a
  single replica: a second replica would answer half of each conversation from
  an empty session map, and two pods would both run the same Nostr identity.
- `readOnlyRootFilesystem` is fine — the gateway keeps no state on disk.
- To add a second agent later, add an entry to `config/agents.json` and a
  matching `<NAME>_NSEC` key to the Secret; the ConfigMap has a
  `configmap.reloader.stakater.com/reload` annotation, but a restart is the
  cheap way to be sure.
