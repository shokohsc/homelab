#!/usr/bin/env bash
set -e

while IFS= read -r item; do
    curl -LH "Content-Type: application/json" -d "{\"body\": $item}" "${SIDEKICK_API_ENDPOINT}"
done < <(cat ${ITEMS_YAML_PATH} | yq '.watchy[].body' -)

exit 0
