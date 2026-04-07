#!/usr/bin/env bash
set -euo pipefail

: "${PKI_DIR:=./pki}"
: "${SLOT_ROOT:=9d}"
: "${SLOT_INTERMEDIATE:=9c}"

ykman piv keys import "${SLOT_ROOT}" "${PKI_DIR}/root"/private/ca.root.key.pem
ykman piv certificates import "${SLOT_ROOT}" "${PKI_DIR}/root"/certs/ca.root.crt.pem

ykman piv keys import $"${SLOT_INTERMEDIATE}" "${PKI_DIR}/intermediate"/private/ca.intermediate.key.pem
ykman piv certificates import $"${SLOT_INTERMEDIATE}" "${PKI_DIR}/intermediate"/certs/ca.intermediate.crt.pem
