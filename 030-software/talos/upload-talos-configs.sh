#!/bin/sh
# Upload talos configuration files to booter & remote-config node.
# Usage: ./upload-talos-configs.sh

set -euo pipefail

TALOSCONFIGS_HOST="shokohsc@tracer.home.arpa"
REMOTE_CONFIG_PATH="/home/shokohsc/talos-pxe/config"

log() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*"; }

log "Uploading talos configuration files to $TALOSCONFIGS_HOST"
rsync -vz --progress ./clusterconfig/talos-sombra.yaml "$TALOSCONFIGS_HOST:$REMOTE_CONFIG_PATH/m/94-C6-91-A2-82-AD.yaml"
rsync -vz --progress ./clusterconfig/talos-lucio.yaml "$TALOSCONFIGS_HOST:$REMOTE_CONFIG_PATH/m/1C-69-7A-04-0B-76.yaml"
rsync -vz --progress ./clusterconfig/talos-zarya.yaml "$TALOSCONFIGS_HOST:$REMOTE_CONFIG_PATH/m/94-C6-91-1C-FF-2E.yaml"
rsync -vz --progress ./clusterconfig/talos-mercy.yaml "$TALOSCONFIGS_HOST:$REMOTE_CONFIG_PATH/m/1C-69-7A-69-D9-1E.yaml"
rsync -vz --progress ./clusterconfig/talos-winston.yaml "$TALOSCONFIGS_HOST:$REMOTE_CONFIG_PATH/m/70-85-C2-5E-D0-D3.yaml"

rsync -vz --progress ./clusterconfig/talos-worker-vm.yaml "$TALOSCONFIGS_HOST:$REMOTE_CONFIG_PATH/m/00-00-00-01.yaml"
rsync -vz --progress ./clusterconfig/talos-worker-vm-gpu.yaml "$TALOSCONFIGS_HOST:$REMOTE_CONFIG_PATH/m/00-00-00-02.yaml"

rsync -vz --progress ./clusterconfig/talos-worker-vm.yaml "$TALOSCONFIGS_HOST:$REMOTE_CONFIG_PATH/s/worker-vm.yaml"
rsync -vz --progress ./clusterconfig/talos-worker-vm-gpu.yaml "$TALOSCONFIGS_HOST:$REMOTE_CONFIG_PATH/s/worker-vm-gpu.yaml"