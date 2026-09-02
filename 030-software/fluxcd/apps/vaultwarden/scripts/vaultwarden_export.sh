#!/usr/bin/env sh

set -euo pipefail

# -----------------------------------------------------------------------------

npm install -g @bitwarden/cli

# Ensure bw is in PATH
if ! command -v bw >/dev/null 2>&1; then
    echo "Error: 'bw' (Bitwarden CLI) not found in PATH" >&2
    exit 1
fi

# Log in using API key (non‑interactive)
bw config server "$BW_HOST"
SESSION=$(bw login --apikey --raw) || {
    echo "Error: login failed" >&2
    exit 1
}

# Unlock vault
UNLOCK_JSON=$(printf '%s\n' "$MASTER_PASSWORD" \
    | BW_SESSION="$SESSION" bw unlock --raw 2>/dev/null)
if [ -z "$UNLOCK_JSON" ]; then
    echo "Error: unlock failed" >&2
    exit 1
fi

# Use unlocked session token
export BW_SESSION="$UNLOCK_JSON"

# Export vault as JSON
OUT_FILE="$BACKUP_DIR/vaultwarden-$(date +%Y%m%d-%H%M%S).json"

bw export --format json --raw >"$OUT_FILE"

echo "Export written to: $OUT_FILE"

