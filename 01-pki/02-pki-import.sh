#!/usr/bin/env bash
set -euo pipefail

BASE_DIR="$(pwd)/pki"
SLOT_ROOT="${SLOT_ROOT:-9d}"
SLOT_INTERMEDIATE="${SLOT_INTERMEDIATE:-9c}"

ykman piv keys import $SLOT_ROOT $BASE_DIR/root/private/root.key.pem
ykman piv certificates import $SLOT_ROOT $BASE_DIR/root/certs/root.cert.pem

ykman piv keys import $SLOT_INTERMEDIATE $BASE_DIR/intermediate/private/intermediate.key.pem
ykman piv certificates import $SLOT_INTERMEDIATE $BASE_DIR/intermediate/certs/intermediate.cert.pem
