#!/usr/bin/env sh

set -euo pipefail

log () {
    local message=$1
    local level=${2:-INFO}
    local log_level=${LOG_LEVEL:-INFO}

    # Define log levels for comparison
    local level_value
    case $level in
        DEBUG) level_value=0 ;;
        INFO) level_value=1 ;;
        WARN) level_value=2 ;;
        ERROR) level_value=3 ;;
        FATAL) level_value=4 ;;
        *) level_value=1 ;;  # Default to INFO if level is unknown
    esac

    local log_level_value
    case $log_level in
        DEBUG) log_level_value=0 ;;
        INFO) log_level_value=1 ;;
        WARN) log_level_value=2 ;;
        ERROR) log_level_value=3 ;;
        FATAL) log_level_value=4 ;;
        *) log_level_value=1 ;;  # Default to INFO if log_level is unknown
    esac

    if [ $level_value -ge $log_level_value ]; then
        echo "$(date "+%Y-%m-%d %H:%M:%S") [$level]: $message"
    fi
}

# Configuration
PROMETHEUS_SERVER="http://victoria-metrics-vms-server.victoria-metrics.svc.cluster.local:8428"
THRESHOLD_KBPS=${THRESHOLD_KBPS:-500}  # Threshold in kilobits per second
WEBHOOK_URL="http://shell2http.shell2http.svc.cluster.local/vpn-egress-gateway/restart"

DELUGE_URL="http://deluge.deluge.svc.cluster.local/json"
COOKIES_PATH="/tmp/deluge_auth_cookies.txt"

# Convert threshold to bytes per second
THRESHOLD_BPS=$((THRESHOLD_KBPS * 1000))

# Prometheus query to calculate average download rate over the last 5 minutes
# QUERY='avg by (namespace, pod) (rate(container_network_receive_bytes_total{namespace="deluge", pod=~"deluge.*", pod!="", interface="vxlan0"}[5m:1m]))'
QUERY='avg by (namespace) (rate(container_network_receive_bytes_total{namespace="vpn-egress-gateway", pod=~"vpn-egress-gateway.*", pod!~"vpn-egress-gateway-webhook.*",interface="tun0"}[5m:1m]))'
# Execute the Prometheus query
RESPONSE=$(curl --connect-timeout 2 -s -G --data-urlencode "query=$QUERY" "$PROMETHEUS_SERVER/api/v1/query")

# Extract the average download rate from the JSON response
AVG_DL_RATE=$(echo "$RESPONSE" | jq -r '.data.result[0].value[1]')
ARG_AVG_DL_RATE=$(printf "%.0f" "$AVG_DL_RATE")

# Convert the average download rate to KB/s or MB/s
if [ "$ARG_AVG_DL_RATE" -lt 1000000 ]; then
    AVG_DL_RATE_KBPS=$(printf "%.2f" "$(echo "$AVG_DL_RATE / 1000" | bc -l)")
    FORMATTED_AVG_DL_RATE="${AVG_DL_RATE_KBPS} KB/s"
else
    AVG_DL_RATE_MBPS=$(printf "%.2f" "$(echo "$AVG_DL_RATE / 1000000" | bc -l)")
    FORMATTED_AVG_DL_RATE="${AVG_DL_RATE_MBPS} MB/s"
fi

log "Authenticating to deluge" 'DEBUG'
curl --connect-timeout 2 -c "$COOKIES_PATH" -s -o /dev/null -X POST -H "Content-Type: application/json" -d '{"method": "auth.login","params": ["deluge"],"id": 1}' "$DELUGE_URL"

if [ $? -ne 0 ]; then
    log "Failed to authenticate to deluge" 'ERROR'

    RESTART_COUNT=$(kubectl get pod -l "app.kubernetes.io/name=vpn-egress-gateway"  -n vpn-egress-gateway -o json | jq '.items[].status.containerStatuses[].restartCount' | awk '{sum+=$1} END {print sum}')
    if [ "${RESTART_COUNT}" -gt 8 ]; then
        log "Restart count is ${RESTART_COUNT}, restarting vpn-egress-gateway & deluge/deluge"
        kubectl rollout restart deployment/vpn-egress-gateway -n vpn-egress-gateway
        kubectl rollout restart deployment/deluge -n deluge
        exit 0
    fi

    exit 1
fi

log "Retrieving downloading torrent total" 'DEBUG'
ACTIVE_DL_TORRENTS_TOTAL=$(curl --connect-timeout 2 -b "$COOKIES_PATH" -s -X POST -H "Content-Type: application/json" -d '{"method": "core.get_torrents_status","params": [{"state":["Downloading"]}, ["state"]],"id": 2}' "$DELUGE_URL" | grep -o '"state":' | wc -l)

# Check if the average download rate is below the threshold and there are active downloads
if [ "$ARG_AVG_DL_RATE" -lt "$THRESHOLD_BPS" ] && [ "$ACTIVE_DL_TORRENTS_TOTAL" -gt 0 ]; then
    log "Average download rate ${FORMATTED_AVG_DL_RATE} is below threshold ($THRESHOLD_KBPS KB/s) and ${ACTIVE_DL_TORRENTS_TOTAL} downloading active torrents. "
    # Prepare the payload for the webhook
    PAYLOAD=$(jq -n \
    --arg rate "$FORMATTED_AVG_DL_RATE" \
    --arg threshold "$THRESHOLD_BPS" \
    '{text: "Alert: Average download rate ($rate B/s) is below the threshold ($threshold B/s)."}')

    # Trigger the webhook
    log "Triggering webhook" 'DEBUG'
    curl --connect-timeout 2 -s -X POST -H 'Content-type: application/json' --data "$PAYLOAD" "$WEBHOOK_URL"
else
    log "Average download rate ${FORMATTED_AVG_DL_RATE} is above threshold ($THRESHOLD_KBPS KB/s) and ${ACTIVE_DL_TORRENTS_TOTAL} downloading active torrents."
fi

# Clean up
rm -f "$COOKIES_PATH"

exit 0