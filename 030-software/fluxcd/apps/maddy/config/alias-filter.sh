#!/usr/bin/env sh

set -e

notify() {
  wget -O- --post-data="{\"channel_id\": \"$MATTERMOST_CHANNEL\", \"message\": \"$1\"}" \
    --header='Content-Type: application/json' \
    --header="Authorization: Bearer $(echo $MATTERMOST_TOKEN)" \
    --header='User-Agent: maddy-alias-filter/v1' \
    http://mattermost.mattermost:8065/api/v4/posts || true
}

BAN_LIST_PATH=${BAN_LIST_PATH:-/config/ban-list}
SPAM_DOMAIN_LIST_PATH=${SPAM_DOMAIN_LIST_PATH:-/config/spam-domain-list}
QUARANTINE_LIST_PATH=${QUARANTINE_LIST_PATH:-/config/quarantine-list}

alias=$(echo "$1" | cut -d "@" -f1 | cut -d "+" -f2 | cut -d "." -f2 | awk '{print tolower($0)}')
spam_domain=$(echo "$1" | cut -d "@" -f2 | awk '{print tolower($0)}')
sender=$(echo "$2" | awk '{print tolower($0)}')
sender_domain=$(echo "$2" | cut -d "@" -f2 | awk '{print tolower($0)}')
source_ip=$(echo "$3" | awk '{print tolower($0)}')
source_host=$(echo "$4" | awk '{print tolower($0)}')
source_rdns=$(echo "$5" | awk '{print tolower($0)}')

while IFS= read -r spam_source
do
  if [ "$spam_source" == "$sender_domain" ]; then
    notify "To $(echo $1 | awk '{print tolower($0)}'): Banned spam from $sender $source_ip $source_host $source_rdns (Matched $2 to $sender_domain)"
    exit 1
  fi
done < "$SPAM_DOMAIN_LIST_PATH"

while IFS= read -r ban
do
  if [ "$ban" == "$alias" ]; then
    notify "To $(echo $1 | awk '{print tolower($0)}'): Banned mail from $sender $source_ip $source_host $source_rdns (Matched $1 to $alias)"
    exit 1
  fi
done < "$BAN_LIST_PATH"

while IFS= read -r quarantine
do
  if [ "$quarantine" == "$alias" ]; then
    notify "To $(echo $1 | awk '{print tolower($0)}'): Quarantined mail from $sender $source_ip $source_host $source_rdns (Matched $1 to $alias)"
    exit 2
  fi
done < "$QUARANTINE_LIST_PATH"

while IFS= read -r spam
do
  if [ "$spam" == "$spam_domain" ]; then
    notify "To $(echo $1 | awk '{print tolower($0)}'): Quarantined spam from $(echo $1 | awk '{print tolower($0)}') (Matched $2 to $spam_domain)"
    exit 2
  fi
done < "$SPAM_DOMAIN_LIST_PATH"

notify "To $(echo $1 | awk '{print tolower($0)}'): Received mail from $sender $source_ip $source_host $source_rdns"
exit 0