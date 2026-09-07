#!/usr/bin/env sh

set -euo pipefail

# Logging function
log () {
    echo "$(date "+%Y-%m-%d %H:%M:%S") [${2:-INFO}]: $1"
}

# URL of the trackers list
TRACKERS_URL="https://raw.githubusercontent.com/ngosang/trackerslist/master/trackers_best.txt"
DELUGE_URL="http://deluge.deluge.svc.cluster.local/json"
COOKIES_PATH="/tmp/deluge_cookies.txt"

# # Lock file path
# LOCK_FILE="/tmp/auto_add_trackers.lock"

# # Function to acquire lock
# acquire_lock() {
#     while [ -f "$LOCK_FILE" ]; do
#         log "Lock file exists. Waiting..."
#         sleep 5
#     done
#     touch "$LOCK_FILE"
#     log "Lock acquired"
# }

# # Function to release lock
# release_lock() {
#     rm -f "$LOCK_FILE"
#     log "Lock released"
# }

# # Trap to release lock on script exit
# trap release_lock EXIT

# # Acquire lock
# acquire_lock

# Download the latest trackers list
trackers=$(curl --connect-timeout 2 -s "$TRACKERS_URL")

# Check if the download was successful
if [ $? -ne 0 ]; then
    log "Failed to download trackers list"
    exit 1
fi

# Clean the trackers list, removing empty lines
trackers=$(echo "$trackers" | grep -v '^$')

log "Authenticating to deluge" 'DEBUG'
curl --connect-timeout 2 -c $COOKIES_PATH -s -o /dev/null -X POST -H "Content-Type: application/json" -d '{"method": "auth.login","params": ["deluge"],"id": 1}' "$DELUGE_URL"

# Get the list of torrents
torrent_list=$(curl --connect-timeout 2 -b $COOKIES_PATH -s -X POST -H "Content-Type: application/json" -d '{"method": "core.get_torrents_status","params": [{"state":["Downloading"]}, ["name","hash"]],"id": 2}' "$DELUGE_URL" | jq -r '.result | keys[]')

# Check if the torrent list was retrieved successfully
if [ $? -ne 0 ]; then
    log "Failed to retrieve torrent list"
    exit 1
fi

# Add each tracker to each torrent
for torrent_id in $torrent_list; do
    echo "$trackers" | while read -r tracker; do
        if [ -n "$tracker" ]; then
            # Get the current trackers for the torrent
            response=$(curl --connect-timeout 2 -b $COOKIES_PATH -s -X POST -H "Content-Type: application/json" -d '{"method": "web.get_torrent_status", "params": ["'"$torrent_id"'", ["trackers"]], "id": 1}' "$DELUGE_URL")
            current_trackers=$(echo $response | jq -r '.result.trackers[].url')

            # Check if the tracker is already added
            if ! echo "$current_trackers" | grep -q "$tracker"; then
                # Add the tracker to the torrent
                set -x
                curl --connect-timeout 2 -b $COOKIES_PATH -s -X POST -H "Content-Type: application/json" -d '{"method": "common.create_magnet_uri", "params": ["'"$torrent_id"'", {"trackers": ["'"$tracker"'"]}], "id": 1}' "$DELUGE_URL"
                curl --connect-timeout 2 -b $COOKIES_PATH -s -X POST -H "Content-Type: application/json" -d '{"method": "core.add_torrent_magnet", "params": ["'"$uri"'", {}], "id": 1}' "$DELUGE_URL"
                set +x
                log "Added tracker: $tracker to torrent: $torrent_id"
            fi
        fi
    done
done

log "Trackers added successfully to all torrents"

# Clean up
rm -f $COOKIES_PATH

exit 0