#!/usr/bin/env sh

set -e

notify() {
  exit 0 # TODO Remove once notification service up
  wget -O- --post-data="{\"channel_id\": \"$MATTERMOST_CHANNEL\", \"message\": \"$1\"}" \
    --header='Content-Type: application/json' \
    --header="Authorization: Bearer $(echo $MATTERMOST_TOKEN)" \
    --header='User-Agent: maddy-alias-filter/v1' \
    http://mattermost.mattermost:8065/api/v4/posts || true
}

BAN_LIST_PATH=${BAN_LIST_PATH:-/config/ban-list}
QUARANTINE_LIST_PATH=${QUARANTINE_LIST_PATH:-/config/quarantine-list}

alias=$(echo "$1" | cut -d "@" -f1 | cut -d "+" -f2 | cut -d "." -f2 | awk '{print tolower($0)}')
sender=$(echo "$2" | awk '{print tolower($0)}')
source_ip=$(echo "$3" | awk '{print tolower($0)}')
source_host=$(echo "$4" | awk '{print tolower($0)}')
source_rdns=$(echo "$5" | awk '{print tolower($0)}')

while IFS= read -r banned
do
  if [ "$banned" == "$alias" ]; then
    notify "To $(echo $1 | awk '{print tolower($0)}'): Banned mail from $sender"
    exit 1
  fi
done < "$BAN_LIST_PATH"

while IFS= read -r quarantined
do
  if [ "$quarantined" == "$alias" ]; then
    notify "To $(echo $1 | awk '{print tolower($0)}'): Quarantined mail from $sender"
    exit 2
  fi
done < "$QUARANTINE_LIST_PATH"

#if [ "$sender" == "${sender/${publicDomain}/}" ]; then
#  notify "To $(echo $1 | awk '{print tolower($0)}'): Quarantined mail from $sender"
#  notify "Info: Sender: $sender, $source_ip, $source_host, $source_rnds"
#  exit 2
#fi


notify "To $(echo $1 | awk '{print tolower($0)}'): Received mail from $sender"
exit 0