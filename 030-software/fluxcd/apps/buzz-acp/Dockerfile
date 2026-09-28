# Bridge image for the Buzz -> OpenCode agent bridge.
# Built and pushed by .github/workflows/buzz-acp-image.yml to ghcr.io/shokohsc/buzz-acp.
#
# buzz-acp is the Buzz side of the ACP harness: it connects to the relay over Nostr,
# forwards @mentions to an ACP agent over stdio and gives that agent the `buzz` CLI.
# The agent itself is the same OpenCode binary the KubeOpenCode agents use, it is
# copied into /tools by the opencode-init container at pod start (same as the main
# agent), so only the two Rust binaries are baked in here.
FROM rust:1.88-bookworm AS builder

RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    pkg-config \
    libssl-dev \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

ARG BUZZ_REF=main

WORKDIR /src
RUN git clone --depth=1 --branch "$BUZZ_REF" https://github.com/block/buzz.git .

# The gateway terminates the relay TLS with a cert-manager CA issuer ("Homelab
# Intermediate CA"). tokio-tungstenite is built with `rustls-tls-webpki-roots`,
# a Mozilla bundle compiled into the binary, so it would reject that cert no
# matter what SSL_CERT_FILE says. `rustls-tls-native-roots` makes it read the
# system store (and is purely additive, webpki roots are kept), which the
# `homelab-ca-cm` trust bundle feeds. reqwest 0.13 already uses the platform
# verifier, so only the websocket side needs this.
RUN sed -i 's/"rustls-tls-webpki-roots"/"rustls-tls-webpki-roots", "rustls-tls-native-roots"/' Cargo.toml \
    && grep -q 'rustls-tls-native-roots' Cargo.toml

RUN cargo build --release -p buzz-acp -p buzz-cli \
    && strip target/release/buzz-acp \
    && strip target/release/buzz

FROM ghcr.io/kubeopencode/kubeopencode-agent-devbox:latest

COPY --from=builder /src/target/release/buzz-acp /usr/local/bin/buzz-acp
COPY --from=builder /src/target/release/buzz /usr/local/bin/buzz

ENTRYPOINT ["/usr/local/bin/buzz-acp"]
