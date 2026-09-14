#!/bin/sh

set -euo pipefail

API_URL="http://api.sidekick.svc.cluster.local:3000/api/deluge/trackers"

curl --connect-timeout 2 -X PATCH "$API_URL"

echo "Done, exiting..."
exit 0
