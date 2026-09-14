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

# # Define the deployment name
# DEPLOYMENT_NAME="vpn-egress-gateway"
# NAMESPACE="vpn-egress-gateway"  # Optional: specify the namespace if not using the default

# # Get the pod names associated with the deployment
# # POD_NAMES=$(kubectl get pods -l app.kubernetes.io/name=$DEPLOYMENT_NAME -n $NAMESPACE -o json | jq -r '.items[].metadata.name')
# POD_NAME=$(kubectl get pods -l app.kubernetes.io/name=$DEPLOYMENT_NAME -n $NAMESPACE -o json | jq -r '.items[].metadata.name')

# # # Print the pod names
# # echo "Pods associated with deployment '$DEPLOYMENT_NAME':"
# # echo "$POD_NAME"


# # Variables
# # POD_NAME="your-pod-name"
# NAMESPACE="vpn-egress-gateway"
# CONTAINER_NAME="openvpn"

# # Check if the pod is running
# POD_STATUS=$(kubectl get pod $POD_NAME -n $NAMESPACE -o json | jq -r '.status.phase')
# if [ "$POD_STATUS" != "Running" ]; then
#   echo "Pod $POD_NAME is not running. Current status: $POD_STATUS"
#   exit 1
# fi

# # Check if the container is running
# CONTAINER_STATUS=$(kubectl get pod $POD_NAME -n $NAMESPACE -o json | jq -r '.status.containerStatuses[] | select(.name == "'$CONTAINER_NAME'") | .state.running')
# if [ -z "$CONTAINER_STATUS" ] || [ "$CONTAINER_STATUS" == "null" ]; then
#   echo "Container $CONTAINER_NAME is not running."
#   exit 1
# fi

# # Execute a command in the container
# kubectl exec -it $POD_NAME -n $NAMESPACE -c $CONTAINER_NAME -- /bin/bash -c "your-command-here"


PID=$(kubectl exec deployment/vpn-egress-gateway -n vpn-egress-gateway -c openvpn -- ps aux |grep /usr/bin/get_ovpn_profile.sh |awk '{print $1}' | head -n 1)
kubectl exec deployment/vpn-egress-gateway -n vpn-egress-gateway -c openvpn -- kill -TERM "${PID}"

log "Killed process: ${PID}, exiting..."
exit 0