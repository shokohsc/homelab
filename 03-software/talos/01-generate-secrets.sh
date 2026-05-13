#!/usr/bin/env bash
set -euo pipefail

echo "=== Generating secrets bundle ==="
echo ""
echo "This creates secrets.yaml with auto-generated cluster PKI."
echo ""
echo "If you already have a secrets.yaml from a previous run,"
echo "delete it first: rm -f secrets.yaml"
echo ""

talosctl gen secrets --force -o secrets.yaml

echo ""
echo "secrets.yaml generated successfully."
echo ""
echo "Next: Set your env vars and run generate-configs.sh:"
echo ""
echo "  export VIP_IP=10.42.20.5"
echo '  export CA_CERT="$(cat /path/to/your-ca.crt)"'
echo "  ./generate-configs.sh"
