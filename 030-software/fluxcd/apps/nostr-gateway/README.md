# nostr-gateway

Bridges [Nostr](https://github.com/nostr-protocol/nostr) to the KubeOpenCode
`nostr-gateway` agent. Messages arrive as Nostr events of kind `30078`, are NIP-44
encrypted to the agent's key, and are turned into an OpenCode session. Replies
are published back as encrypted events. There is also a small plain-HTTP API for
callers that are not on Nostr.

Source: <https://github.com/shokohsc/nostr-gateway>

## Image

`ghcr.io/shokohsc/nostr-gateway:9656caf` — the tag upstream CI publishes from
its main branch (`short=${GITHUB_SHA::7}`), so the reference is immutable. Bump
it, and this README's verification note, when upstream lands a new merge.

That tag is the short SHA of the **merge commit**, so it cannot be guessed from a
pull request branch. The NIP-42 support below is not in `9656caf`; bump to the
merge SHA of <https://github.com/shokohsc/nostr-gateway/pull/4> once it lands.

## Topology

- `nostr-gateway.workspace.svc.cluster.local:4096` is the KubeOpenCode server
  created from the `nostr-gateway` AgentTemplate.
  `config/agents.json` points the gateway at it. `main` in the template is a
  context name, not the agent name.
- The gateway itself is ClusterIP only. Nothing is exposed through the
  `cilium` Gateway, on purpose: Nostr is the public ingress and the HTTP API is
  an in-cluster convenience.
- `allow` in `config/agents.json` gates *Nostr* senders, not HTTP callers. It is
  matched against the pubkey that signed the event, so an event with a forged
  `sender` field does not get through. An empty list allows everyone — do not
  ship that.

## Setup

The identity, the API token and the encrypted Secret are already in place, so
there is nothing left to fill in. What no manifest can do is enrol the agent on
the relay: that is a Nostr event, signed by a key the relay already trusts.

### Enrol the agent on the Buzz relay (the one manual step)

`apps/buzz` runs with `BUZZ_REQUIRE_RELAY_MEMBERSHIP=true`, so the relay refuses
every REQ and every EVENT from a pubkey that is not a member — even after a
valid NIP-42 `AUTH`. Until the agent is a member the subscription is closed with
`auth-required: verification failed` and the gateway is deaf.

The pubkey to enrol is the `npub` in `config/agents.json`:

```text
613ff42687c408eb3ef8772ff967b4c1c51ed135cd9dd83fb4ab7379ea1808cc
```

Publish a NIP-43 `RELAY_ADMIN_ADD_MEMBER`: kind `9030`, empty content, a
single `p` tag holding that pubkey hex, signed by a pubkey that is already an
`owner` or `admin` of the relay. `RELAY_OWNER_PUBKEY` in
`apps/buzz/secret.yaml` is the owner generated at install time. Any Nostr
client that can sign and publish an arbitrary event will do; re-publishing is a
no-op when the member already exists, so it is safe to repeat.

With direct database access instead of a client:

```sh
buzz-admin add-member 613ff42687c408eb3ef8772ff967b4c1c51ed135cd9dd83fb4ab7379ea1808cc member
```

Neither path is wired as a manifest in this repository, so it stays a manual
step by design.

### NIP-42 needs nothing here

The gateway answers the relay's `AUTH` challenge with the agent's own
`AGENT_NSEC` — that is the image's job, not configuration. Two things must
still line up:

- `RELAY_URL` in `apps/buzz/deployment.yaml` and `NOSTR_RELAYS` here must be
  the same URL. NIP-42 requires the `relay` tag of the `AUTH` event to match
  the relay, and the gateway fills that tag with the URL it dialled. Both are
  `wss://relay.buzz.${domain}`, so they agree.
- The image must be new enough to have the auth handler. `9656caf` does not;
  see the note under **Image**.

## Verifying after deploy

```sh
kubectl -n nostr-gateway logs deploy/nostr-gateway
```

A healthy start logs the relays it connected to. Then, from inside the cluster:

```sh
TOKEN=$(kubectl -n nostr-gateway get secret nostr-gateway \
  -o jsonpath='{.data.GATEWAY_TOKEN}' | base64 -d)

curl -H "Authorization: Bearer $TOKEN" \
  -d '{"agent":"nostr-gateway","type":"message","payload":{"text":"say hi"}}' \
  http://nostr-gateway.nostr-gateway.svc.cluster.local/v1/messages

# the reply is a JSON envelope; take its conversation id and stream it
curl -H "Authorization: Bearer $TOKEN" \
  http://nostr-gateway.nostr-gateway.svc.cluster.local/v1/conversations/<id>/events
```

`GET /healthz` is unauthenticated and is what the probes use.

The HTTP API works even when the Nostr side does not, so it says nothing about
the relay. For that, read the log — a healthy agent logs no `nostr notice` at
all, and the two failures are distinguishable:

| log line | meaning |
| --- | --- |
| `nostr notice ... "auth-required: authenticate before subscribing"` | the image is too old to answer NIP-42; bump it |
| `nostr notice ... "auth-required: verification failed"` | authenticated, but the pubkey is not a relay member |

## Notes

- Conversations live in memory only, and the deployment is `Recreate` with a
  single replica: a second replica would answer half of each conversation from
  an empty session map, and two pods would both run the same Nostr identity.
- `readOnlyRootFilesystem` is fine — the gateway keeps no state on disk.
- To add a second agent later, add an entry to `config/agents.json` and a
  matching `<NAME>_NSEC` key to the Secret; the ConfigMap has a
  `configmap.reloader.stakater.com/reload` annotation, but a restart is the
  cheap way to be sure.
- The agent does not show up in the Buzz web client, and that is not a symptom.
  `buzz-web` builds its Agents view from kind `10100` agent-profile events, and
  the gateway publishes only kind `30078`. The test for the Nostr side is the
  log, or any client that lets you send a kind `30078` to the agent's pubkey.
