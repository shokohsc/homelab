#!/bin/sh

set -euo pipefail

TOKEN=${TOKEN:-token}
TARGET_DIRECTORY=${TARGET_DIRECTORY:-/archive}
KARAKEEP_URL=${KARAKEEP_URL:-karakeep.karakeep.svc.cluster.local}

log () {
  echo "$(date "+%Y-%m-%d %H:%M:%S") [${2:-INFO}]: $1"
}

log "Saving lists..."
curl \
  -vL \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer ${TOKEN}" \
  -o ${TARGET_DIRECTORY}/lists.json \
  http://${KARAKEEP_URL}/api/v1/lists

log "Saving bookmarks..."
curl \
  -vL \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer ${TOKEN}" \
  -o ${TARGET_DIRECTORY}/bookmarks.json \
  http://${KARAKEEP_URL}/api/v1/bookmarks?includeContent=false

exit 0
