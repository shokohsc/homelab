#!/bin/sh

set -euo pipefail

TOKEN=${TOKEN:-token}
TARGET_DIRECTORY=${TARGET_DIRECTORY:-/archive}
KARAKEEP_URL=${KARAKEEP_URL:-http://karakeep.karakeep.svc.cluster.local/api/v1/bookmarks}
FINAL_FILE="$TARGET_DIRECTORY/bookmarks.txt"
TEMP_DIR="/tmp"

cursor=""
page=1

while true; do
  echo "Fetching page $page..."
  
  if [ -z "$cursor" ]; then
    response=$(curl -s -H "Authorization: Bearer $TOKEN" \
                    -H "Accept: application/json" \
                    "$KARAKEEP_URL?includeContent=false&limit=100")
  else
    response=$(curl -s -H "Authorization: Bearer $TOKEN" \
                    -H "Accept: application/json" \
                    "$KARAKEEP_URL?includeContent=false&limit=100&cursor=$cursor")
  fi

  # Stop if no bookmarks
  count=$(echo "$response" | jq '.bookmarks | length')
  [ "$count" -eq 0 ] && break

  # Write current batch to file
  echo "$response" | jq '.bookmarks[].content.url' > "$TEMP_DIR/page_${page}.json"

  cursor=$(echo "$response" | jq -r '.nextCursor')
  [ "$cursor" == "null" ] && break

  page=$((page + 1))
done

# Merge all into one file safely using jq slurp
cat "$TEMP_DIR"/*.json > "$FINAL_FILE"
echo "All bookmarks saved to $FINAL_FILE"
