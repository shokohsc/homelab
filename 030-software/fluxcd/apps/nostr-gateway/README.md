# nostr-gateway

Bridges [Nostr](https://github.com/nostr-protocol/nostr) to the KubeOpenCode
`nostr-gateway` agent. Messages arrive as Nostr events of kind `30078`, are NIP-44
encrypted to the agent's key, and are turned into an OpenCode session. Replies
are published back as encrypted events. There is also a small plain-HTTP API for
callers that are not on Nostr.

Source: <https://github.com/shokohsc/nostr-gateway>

## Image

`ghcr.io/shokohsc/nostr-gateway:cfd3a6c` — the tag upstream CI publishes from
its main branch (`short=${GITHUB_SHA::7}`), so the reference is immutable. It is
the short SHA of the **merge commit**, so it cannot be guessed from a pull
request branch. `deployment.yaml` pins the same tag: bump both, plus the
troubleshooting table under **Verifying after deploy**, when upstream lands a new
merge.

This image has both NIP-42 and the Buzz transport in it, and it is past
<https://github.com/shokohsc/nostr-gateway/pull/6>, so the Buzz log lines below
mean what they say: `buzz: agent is in no channel yet` is only ever a discovery
result, never a lost NIP-42 handshake.

## Topology

- `nostr-gateway.workspace.svc.cluster.local:4096` is the KubeOpenCode server
  created from the `nostr-gateway` AgentTemplate.
  `config/agents.json` points the gateway at it. `main` in the template is a
  context name, not the agent name.
- The gateway itself is ClusterIP only. Nothing is exposed through the
  `cilium` Gateway, on purpose: Nostr is the public ingress and the HTTP API is
  an in-cluster convenience.
- `allow` in `config/agents.json` gates *Nostr* senders **and Buzz channel
  senders**; it does not gate HTTP callers. It is matched against the pubkey that
  signed the event, so an event with a forged `sender` field does not get
  through. An empty list allows everyone — do not ship that. A Buzz sender who
  is not on the list is dropped before the relay ever delivers the event, so a
  stale entry does not degrade, it silences the agent: see **A silent agent** at
  the end.

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
2b0b84a37dd43103555d7a2947ae2b47ce6419ab17f357b150ee54fc49ec0c65
```

Publish a NIP-43 `RELAY_ADMIN_ADD_MEMBER`: kind `9030`, empty content, a
single `p` tag holding that pubkey hex, signed by a pubkey that is already an
`owner` or `admin` of the relay. `RELAY_OWNER_PUBKEY` in
`apps/buzz/secret.yaml` is the owner generated at install time. Any Nostr
client that can sign and publish an arbitrary event will do; re-publishing is a
no-op when the member already exists, so it is safe to repeat.

With direct database access instead of a client:

```sh
buzz-admin add-member 2b0b84a37dd43103555d7a2947ae2b47ce6419ab17f357b150ee54fc49ec0c65 member
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
- The image must be new enough to have the auth handler. `cfd3a6c` has it —
  the pool answers the challenge with `AGENT_NSEC` and re-sends the request.

`NOSTR_RELAYS` and `BUZZ_RELAYS` are the same URL here. That is deliberate — one
relay to deploy — but each agent gets its own pool per role, so the kind-30078
listener and the Buzz discovery answer a NIP-42 challenge on separate
connections. Sharing one pool is what made the gateway deaf in
<https://github.com/shokohsc/nostr-gateway/pull/6>: go-nostr builds *identical*
auth events when two subscriptions answer the same challenge in the same second
and keys its `OK` waiters by event id, so the loser waited out its timeout and
the Buzz discovery came back empty with the member list right there.

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
| `buzz: discovery came back with no member lists` | the channel query returned nothing, so the gateway asks again instead of believing it. Harmless on its own — the line that follows is the one to read |
| `buzz: agent is in no channel yet` | the relay *answered*, and no kind-`39002` member list on it names the agent's pubkey. It really is in no channel: add it to one, then reconcile the rosters with `buzz-admin reconcile-channels` |

A mention that reaches the agent logs nothing of its own — the visible proof is
the answer, which the gateway posts back into the channel as a kind-`9` signed
with the agent's own key. So a healthy mention shows up in the Buzz UI, and its
absence is the fault to chase. The Nostr side is the opposite: there the answer
is a kind-`30078` envelope to your key and never appears in a channel.

Every channel message the gateway *refuses* — not on the allow list, not in a
channel the agent is in, no `@mention` in a group — is dropped before it becomes
a prompt, and this image drops it without a word. So the absence of an answer is
not a fault the log can point at; read the allow list instead.

## A silent agent

An agent that is in a channel, is a relay member, and never answers is almost
always an `allow` list that no longer matches who is typing. Buzz mints its key
in the browser and keeps it in local storage, so a new browser, a cleared
profile or a second device is a *new pubkey*, and an entry written months ago
names nobody who is in the room now. The gateway drops such a message before it
is a prompt, so the only symptom is an agent that hears nothing: no error, no
warning, and on the relay side nothing but a channel that has gone quiet.

Ask the relay who has actually been talking to it. The ingest lines carry only a
connection id, so the pubkey comes from the NIP-42 handshake that connection
completed:

```sh
kubectl -n buzz logs deploy/relay --since=1h \
  | grep '"NIP-42 auth successful"' \
  | grep -o '"pubkey":"[0-9a-f]*"' | sort | uniq -c | sort -rn
```

Everything there except the agent's own `npub` belongs in `allow`. Then:

```sh
kubectl -n nostr-gateway rollout restart deploy/nostr-gateway
```

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
  connection is refused. The log line `buzz: published agent profile` is the
  confirmation that it worked.
- The test for the Nostr side is the log, or any client that can send a kind
  `30078` to the agent's pubkey.
