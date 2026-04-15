#!/usr/bin/env bash
set -euo pipefail

: "${PKI_DIR:=./pki}"
: "${PIN_CODE:=000000}"
: "${SLOT_ROOT:=9d}"
: "${SLOT_INTERMEDIATE:=9c}"

ykman piv keys import --pin "${PIN_CODE}" "${SLOT_ROOT}" "${PKI_DIR}/root"/private/ca.root.key.pem
ykman piv certificates import --pin "${PIN_CODE}" "${SLOT_ROOT}" "${PKI_DIR}/root"/certs/ca.root.crt.pem

ykman piv keys import --pin "${PIN_CODE}" $"${SLOT_INTERMEDIATE}" "${PKI_DIR}/intermediate"/private/ca.intermediate.key.pem
ykman piv certificates import --pin "${PIN_CODE}" $"${SLOT_INTERMEDIATE}" "${PKI_DIR}/intermediate"/certs/ca.intermediate.crt.pem

ykman piv info