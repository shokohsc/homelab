# nostr-gateway

Bridges [Nostr](https://github.com/nostr-protocol/nostr) to the KubeOpenCode
`nostr-gateway` agent. Messages arrive as Nostr events of kind `30078`, are NIP-44
encrypted to the agent's key, and are turned into an OpenCode session. Replies
are published back as encrypted events. There is also a small plain-HTTP API for
callers that are not on Nostr.

Source: <https://github.com/shokohsc/nostr-gateway>

## Image

`ghcr.io/shokohsc/nostr-gateway:1046469` — the tag upstream CI publishes from
its main branch (`short=${GITHUB_SHA::7}`), so the reference is immutable. It is
the short SHA of the **merge commit**, so it cannot be guessed from a pull
request branch. `deployment.yaml` pins the same tag: bump both, plus the
troubleshooting table under **Verifying after deploy**, when upstream lands a new
merge.

This image has both NIP-42 and the Buzz transport in it. The Buzz fixes in
<https://github.com/shokohsc/nostr-gateway/pull/6> are *not* in `1046469`; bump to
that merge SHA once it lands, or keep reading the Buzz log lines below, because
`buzz: agent is in no channel yet` means two different things in the two images.

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
  the same URL. NIP-42 requires the `relay` tag of the `AUTH` event to match the
  relay, and the gateway fills that tag with the URL it dialled. Both are
  `wss://relay.buzz.${domain}`, so they agree.
- The image must be new enough to have the auth handler. `1046469` has it —
  the pool answers the challenge with `AGENT_NSEC` and re-sends the request.

`NOSTR_RELAYS` and `BUZZ_RELAYS` are the same URL here. That is deliberate — one
relay to deploy — but it puts two subscriptions on one connection, and go-nostr
builds *identical* auth events when two of them answer the same challenge in the
same second. It keys the `OK` waiters by event id, so one of the two waits out
its timeout and gives up instead of re-subscribing; the other carries on. Up to
<https://github.com/shokohsc/nostr-gateway/pull/6> the loser was usually the Buzz
channel discovery, which reported `buzz: agent is in no channel yet` — a wrong
answer that cost a full minute of deafness.

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

The Buzz side logs its own lines, and they are worth reading in order — being a
member of the *relay* (the step above) and being in a *channel* are two different
things, and only the second one makes a mention reach the agent:

| log line | meaning |
| --- | --- |
| `msg="buzz channels" ... channels=<uuids>` | discovery worked; this is the healthy line, and a mention in one of those uuids reaches the agent |
| `buzz: published agent profile` | the agent is now visible as an agent in Buzz (see the note at the end) |
| `buzz: discovery came back with no member lists` | the channel query returned nothing, so the gateway asks again instead of believing it. Harmless on its own, and in `1046469` the line that follows is the one to read |
| `buzz: agent is in no channel yet` | the relay *answered*, and no kind-`39002` member list on it names the agent's pubkey. It really is in no channel: add it to one, then reconcile the rosters with `buzz-admin reconcile-channels`. In `1046469` this same line also appears when the NIP-42 handshake above was lost, so read it twice before concluding anything |

A mention that reaches the agent logs nothing of its own — the visible proof is
the reply, which is a kind-`30078` event to your key and not a message in the
channel. Channel traffic is inbound only, so no answer ever appears in the Buzz
UI.

## Notes

- Conversations live in memory only, and the deployment is `Recreate` with a
  single replica: a second replica would answer half of each conversation from
  an empty session map, and two pods would both run the same Nostr identity.
- `readOnlyRootFilesystem` is fine — the gateway keeps no state on disk.
- To add a second agent later, add an entry to `config/agents.json` and a
  matching `<NAME>_NSEC` key to the Secret; the ConfigMap has a
  `configmap.reloader.stakater.com/reload` annotation, but a restart is the
  cheap way to be sure.
- The agent appears in Buzz's agent list through a kind-`10100` profile that the
  gateway publishes for itself. It signs it with `AGENT_NSEC`, which is why no
  client can do it instead, and only after a channel query has come back — that
  is what proves NIP-42 passed, because a profile pushed onto an unauthenticated
  connection is refused. Until the merge SHA from
  <https://github.com/shokohsc/nostr-gateway/pull/6> is pinned here, the agent is
  a member of the relay but shows up nowhere in Buzz's agent UI; the log line
  `buzz: published agent profile` is the confirmation that it worked.
- The test for the Nostr side is the log, or any client that can send a kind
  `30078` to the agent's pubkey.
