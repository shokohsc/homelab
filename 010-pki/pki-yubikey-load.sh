#!/usr/bin/env bash
set -euo pipefail

PKI_YUBIKEY_LOAD_VERSION="2.0.0"

: "${PKI_DIR:=./pki}"
: "${PIN_CODE:=000000}"
: "${SLOT_ROOT:=9d}"
: "${SLOT_INTERMEDIATE:=9c}"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_info()  { echo -e "${GREEN}[INFO]${NC} $1"; }
print_warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

check_ykman() {
    if ! command -v ykman &>/dev/null; then
        print_error "ykman is not installed"
        print_error "Install: brew install yubikey-manager  OR  apt install yubikey-manager"
        exit 1
    fi
}

load_root() {
    local key_file="${PKI_DIR}/root/private/ca.root.key.pem"
    local cert_file="${PKI_DIR}/root/certs/ca.root.crt.pem"

    if [[ ! -f "$key_file" ]]; then
        print_error "Root CA key not found: $key_file"
        print_error "Run pki-root-ca.sh first"
        exit 1
    fi
    if [[ ! -f "$cert_file" ]]; then
        print_error "Root CA certificate not found: $cert_file"
        print_error "Run pki-root-ca.sh first"
        exit 1
    fi

    print_info "Loading Root CA key into YubiKey slot ${SLOT_ROOT}..."
    ykman piv keys import --pin "${PIN_CODE}" "${SLOT_ROOT}" "$key_file"

    print_info "Loading Root CA certificate into YubiKey slot ${SLOT_ROOT}..."
    ykman piv certificates import --pin "${PIN_CODE}" "${SLOT_ROOT}" "$cert_file"

    print_info "Root CA loaded successfully (slot ${SLOT_ROOT})"
}

load_intermediate() {
    local key_file="${PKI_DIR}/intermediate/private/ca.intermediate.key.pem"
    local cert_file="${PKI_DIR}/intermediate/certs/ca.intermediate.crt.pem"

    if [[ ! -f "$key_file" ]]; then
        print_error "Intermediate CA key not found: $key_file"
        print_error "Run pki-intermediate-ca.sh first"
        exit 1
    fi
    if [[ ! -f "$cert_file" ]]; then
        print_error "Intermediate CA certificate not found: $cert_file"
        print_error "Run pki-intermediate-ca.sh first"
        exit 1
    fi

    print_info "Loading Intermediate CA key into YubiKey slot ${SLOT_INTERMEDIATE}..."
    ykman piv keys import --pin "${PIN_CODE}" "${SLOT_INTERMEDIATE}" "$key_file"

    print_info "Loading Intermediate CA certificate into YubiKey slot ${SLOT_INTERMEDIATE}..."
    ykman piv certificates import --pin "${PIN_CODE}" "${SLOT_INTERMEDIATE}" "$cert_file"

    print_info "Intermediate CA loaded successfully (slot ${SLOT_INTERMEDIATE})"
}

usage() {
    cat << EOF
YubiKey PIV Load Script v${PKI_YUBIKEY_LOAD_VERSION}

Loads Root CA and/or Intermediate CA keys and certificates into a YubiKey
PIV application. Run the corresponding CA creation script first.

Usage: $0 [root|intermediate|all] [options]

Commands:
  root           Load Root CA key + certificate (slot: SLOT_ROOT)
  intermediate   Load Intermediate CA key + certificate (slot: SLOT_INTERMEDIATE)
  all            Load both (default)

Environment Variables:
  PKI_DIR         PKI directory (default: ./pki)
  PIN_CODE        YubiKey PIV PIN (default: 000000)
  SLOT_ROOT       PIV slot for root CA (default: 9d)
  SLOT_INTERMEDIATE  PIV slot for intermediate CA (default: 9c)

Workflow:
  # Step 1 — create the Root CA, then load it onto the YubiKey
  ./pki-root-ca.sh
  PIN_CODE=123456 ./pki-yubikey-load.sh root

  # Step 2 — create the Intermediate CA (root key can now be on YubiKey)
  ROOT_KEY_LOCATION=pkcs11 \\
  ROOT_KEY_PKCS11_URI="pkcs11:type=private;object=Root%20CA" \\
  ./pki-intermediate-ca.sh

  # Load the Intermediate CA onto the YubiKey
  PIN_CODE=123456 ./pki-yubikey-load.sh intermediate

  # Step 3 — create leaf certs (intermediate key can now be on YubiKey)
  INTERMEDIATE_KEY_LOCATION=pkcs11 \\
  INTERMEDIATE_KEY_PKCS11_URI="pkcs11:type=private;object=Intermediate%20CA" \\
  ./pki-leaf-cert.sh example.com

Verification:
  ykman piv info

EOF
}

main() {
    local command="${1:-all}"

    if [[ "$command" == "-h" || "$command" == "--help" ]]; then
        usage
        exit 0
    fi

    print_info "YubiKey PIV Load Script v${PKI_YUBIKEY_LOAD_VERSION}"
    echo ""

    check_ykman

    case "$command" in
        root)
            load_root
            ;;
        intermediate)
            load_intermediate
            ;;
        all)
            load_root
            load_intermediate
            ;;
        *)
            print_error "Unknown command: '$command'"
            usage
            exit 1
            ;;
    esac

    echo ""
    print_info "YubiKey PIV status:"
    ykman piv info
}

main "$@"
