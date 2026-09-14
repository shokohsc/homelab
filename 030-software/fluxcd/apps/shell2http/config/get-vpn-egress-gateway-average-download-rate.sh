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

# Prometheus query to calculate average download rate over the last 5 minutes
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

echo $FORMATTED_AVG_DL_RATE

exit 0
