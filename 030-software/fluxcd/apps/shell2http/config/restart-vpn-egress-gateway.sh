#!/bin/sh

set -euo pipefail

log () {
    echo "$(date "+%Y-%m-%d %H:%M:%S") [${2:-INFO}]: $1"
}

RESTART_COUNT=$(kubectl get pod -l "app=vpn-egress-gateway"  -n vpn-egress-gateway -o json | jq '.items[].status.containerStatuses[].restartCount' | awk '{sum+=$1} END {print sum}')
if [ "${RESTART_COUNT}" -gt 8 ]; then
    log "Restart count is ${RESTART_COUNT}, restarting vpn-egress-gateway & deluge/deluge"
    kubectl rollout restart deployment/vpn-egress-gateway -n vpn-egress-gateway
    kubectl rollout restart deployment/deluge -n deluge
    exit 0
fi

kubectl rollout restart deployment/vpn-egress-gateway -n vpn-egress-gateway

log "Restart deployment vpn-egress-gateway"
exit 0