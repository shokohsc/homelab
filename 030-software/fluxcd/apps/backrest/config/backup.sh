#!/usr/bin/env sh

set -e

log () {
  echo "$(date "+%Y-%m-%d %H:%M:%S") [${2:-INFO}]: $1"
}

log "Get secrets"

# Get the kubernetes secret list formatted as such: namespace/secret-name
# Save it as /tmp/secrets-list.txt
kubectl get secrets --all-namespaces \
  --no-headers \
  -o custom-columns='NAMESPACE:.metadata.namespace,NAME:.metadata.name' \
  | grep -v '^kube-' \
  | grep -v '^tekton-' \
  | grep -v '^metallb' \
  | grep -v '^pod-gateway' \
  | grep -v '^rook-ceph' \
  | grep -v 'sh.helm.release.v1' \
  | awk '{print $1 "/" $2}' \
  | grep -v '\-token-' \
  | grep -v '\-cert' > /tmp/secrets-list.txt

cat /tmp/secrets-list.txt

log "Backup secrets"

# Parse the /tmp/secrets-list.txt and output each secret in a new yaml file secrets.yaml using kubectl get secret -o yaml
# Add a '---' between each secret on the yaml file
while IFS= read -r secret; do
  namespace=$(echo "$secret" | cut -d "/" -f1)
  name=$(echo "$secret" | cut -d "/" -f2)
  kubectl get secret "$name" -n "$namespace" -o yaml
  echo '---'
done < /tmp/secrets-list.txt > /tmp/secrets.yaml

cp /tmp/secrets.yaml /backup/secrets.yaml

log "Exiting..."
exit 0