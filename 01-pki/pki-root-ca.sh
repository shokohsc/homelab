#!/usr/bin/env bash
set -euo pipefail

PKI_SETUP_VERSION="2.0.0"

# ---------------------------------------------------------------------------
# Root CA — environment variables
# ---------------------------------------------------------------------------
: "${PKI_DIR:=./pki}"
: "${ROOT_CN:=My Root CA}"
: "${ROOT_VALIDITY_DAYS:=3650}"
: "${ROOT_KEY_ALG:=ec}"
: "${ROOT_KEY_SIZE:=prime256v1}"
: "${COUNTRY:=US}"
: "${STATE:=State}"
: "${LOCALITY:=City}"
: "${ORGANIZATION:=Organization}"
: "${ORGANIZATIONAL_UNIT:=IT}"
: "${EMAIL:=ca@example.com}"
: "${AUTO_OVERWRITE:=false}"
: "${CREATE_CRL:=true}"

# ---------------------------------------------------------------------------
# Derived paths (filesystem only — no PKCS#11 at this level)
# ---------------------------------------------------------------------------
ROOT_DIR="${PKI_DIR}/root"
ROOT_PRIVATE_DIR="${ROOT_DIR}/private"
ROOT_CERTS_DIR="${ROOT_DIR}/certs"
ROOT_CRL_DIR="${ROOT_DIR}/crl"
ROOT_SERIAL_FILE="${ROOT_DIR}/serial"
ROOT_INDEX_FILE="${ROOT_DIR}/index.txt"
ROOT_NEWCERTS_DIR="${ROOT_DIR}/newcerts"

ROOT_KEY_FILE="${ROOT_PRIVATE_DIR}/ca.root.key.pem"
ROOT_CERT_FILE="${ROOT_CERTS_DIR}/ca.root.crt.pem"
ROOT_CRL_FILE="${ROOT_CRL_DIR}/root.crl.pem"
ROOT_OPENSSL_CNF="${PKI_DIR}/rootopenssl.cnf"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_openssl() {
    if ! command -v openssl &> /dev/null; then
        print_error "openssl is not installed"
        exit 1
    fi
}

prompt_override() {
    local file="$1"
    if [[ -f "$file" ]]; then
        if [[ "$AUTO_OVERWRITE" == "true" ]]; then
            return 0
        fi
        while true; do
            read -p "File '$file' exists. Overwrite? [y/N] " -n 1 -r
            echo
            case $REPLY in
                [Yy]) return 0 ;;
                [Nn]|"") return 1 ;;
                *) print_warn "Please answer y or n" ;;
            esac
        done
    fi
    return 0
}

check_files_and_prompt() {
    local files=("$@")
    local need_override=false

    for file in "${files[@]}"; do
        if [[ -f "$file" ]]; then
            need_override=true
            break
        fi
    done

    if $need_override; then
        print_warn "Some files already exist in ${PKI_DIR}"
        if [[ "$AUTO_OVERWRITE" != "true" ]]; then
            read -p "Continue and overwrite existing files? [y/N] " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                print_info "Aborted by user"
                exit 0
            fi
        fi
    fi
}

create_directory_structure() {
    print_info "Creating Root CA directory structure..."
    mkdir -p "$ROOT_PRIVATE_DIR" "$ROOT_CERTS_DIR" "$ROOT_CRL_DIR" "$ROOT_NEWCERTS_DIR"
    chmod 700 "$ROOT_PRIVATE_DIR"
    print_info "Directory structure created"
}

init_ca_database() {
    print_info "Initializing Root CA database..."
    [[ ! -f "$ROOT_SERIAL_FILE" ]] && echo "01" > "$ROOT_SERIAL_FILE"
    [[ ! -f "$ROOT_INDEX_FILE" ]] && touch "$ROOT_INDEX_FILE"
}

# Write the OpenSSL config for the Root CA.
# Called once so both generate_root_cert and create_root_crl can use it even
# when the certificate already exists and its generation step is skipped.
write_root_openssl_config() {
    mkdir -p "$(dirname "$ROOT_OPENSSL_CNF")"
    cat > "$ROOT_OPENSSL_CNF" << EOF
[ca]
default_ca = CA_default

[CA_default]
database = ${ROOT_INDEX_FILE}
serial = ${ROOT_SERIAL_FILE}
new_certs_dir = ${ROOT_NEWCERTS_DIR}
certificate = ${ROOT_CERT_FILE}
private_key = ${ROOT_KEY_FILE}
default_md = sha256
default_crl_days = 365
policy = policy_any

[policy_any]
countryName = optional
stateOrProvinceName = optional
organizationName = optional
organizationalUnitName = optional
commonName = supplied
emailAddress = optional

[req]
distinguished_name=req

[v3_ca]
basicConstraints = critical, CA:true
keyUsage = critical, keyCertSign, cRLSign
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid:always,issuer
EOF
}

generate_root_key() {
    print_info "Generating Root CA key..."
    if prompt_override "$ROOT_KEY_FILE"; then
        case "$ROOT_KEY_ALG" in
            rsa)
                openssl genrsa -out "$ROOT_KEY_FILE" "$ROOT_KEY_SIZE"
                ;;
            ec)
                openssl ecparam -name "$ROOT_KEY_SIZE" -genkey -out "$ROOT_KEY_FILE"
                ;;
            *)
                print_error "Unknown key algorithm: $ROOT_KEY_ALG"
                exit 1
                ;;
        esac
        chmod 400 "$ROOT_KEY_FILE"
        print_info "Root CA key generated: $ROOT_KEY_FILE"
    fi
}

generate_root_cert() {
    print_info "Generating Root CA certificate..."
    if prompt_override "$ROOT_CERT_FILE"; then
        local subject="/C=${COUNTRY}/ST=${STATE}/L=${LOCALITY}/O=${ORGANIZATION}/OU=${ORGANIZATIONAL_UNIT}/CN=${ROOT_CN}/emailAddress=${EMAIL}"

        openssl req -config "$ROOT_OPENSSL_CNF" -x509 -new -nodes \
            -key "$ROOT_KEY_FILE" \
            -sha256 \
            -days "$ROOT_VALIDITY_DAYS" \
            -subj "$subject" \
            -out "$ROOT_CERT_FILE" \
            -outform PEM \
            -extensions v3_ca

        chmod 444 "$ROOT_CERT_FILE"
        print_info "Root CA certificate generated: $ROOT_CERT_FILE"
    fi
}

create_root_crl() {
    if [[ "$CREATE_CRL" != "true" ]]; then
        return
    fi

    print_info "Creating Root CA CRL..."
    if prompt_override "$ROOT_CRL_FILE"; then
        openssl ca -batch \
            -config "$ROOT_OPENSSL_CNF" \
            -notext \
            -gencrl \
            -out "$ROOT_CRL_FILE" 2>/dev/null || {
            print_warn "Could not create Root CA CRL"
            return
        }

        if [[ -f "$ROOT_CRL_FILE" ]]; then
            chmod 444 "$ROOT_CRL_FILE"
            print_info "Root CA CRL created: $ROOT_CRL_FILE"
            openssl crl -in "$ROOT_CRL_FILE" -inform PEM -noout -text 2>/dev/null | head -10 || true
        fi
    fi
}

print_summary() {
    echo ""
    echo "=============================================="
    echo "Root CA Setup Complete"
    echo "=============================================="
    echo ""
    echo "Root CA:"
    echo "  Key:    $ROOT_KEY_FILE"
    echo "  Cert:   $ROOT_CERT_FILE"
    echo "  CRL:    $ROOT_CRL_FILE"
    echo ""
    echo "Certificate Details:"
    echo "  CN:        $ROOT_CN"
    echo "  Validity:  $ROOT_VALIDITY_DAYS days"
    echo "  Key:       $ROOT_KEY_ALG ($ROOT_KEY_SIZE)"
    echo ""
    echo "Next step — create the Intermediate CA:"
    echo "  ./pki-intermediate-ca.sh"
    echo ""
}

usage() {
    cat << EOF
Root CA Setup Script v${PKI_SETUP_VERSION}

Usage: $0 [options]

Environment Variables:
  PKI_DIR              Working directory (default: ./pki)

  ROOT_CN              Root CA Common Name (default: My Root CA)
  ROOT_VALIDITY_DAYS   Root certificate validity in days (default: 3650)
  ROOT_KEY_ALG         Root key algorithm: rsa|ec (default: ec)
  ROOT_KEY_SIZE        Root key size: prime256v1|secp384r1|2048|4096 (default: prime256v1)

  COUNTRY              Country code (default: US)
  STATE                State/Province (default: State)
  LOCALITY             City/Locality (default: City)
  ORGANIZATION         Organization name (default: Organization)
  ORGANIZATIONAL_UNIT  Organizational Unit (default: IT)
  EMAIL                Email address (default: ca@example.com)

  CREATE_CRL           Create Root CRL: true|false (default: true)
  AUTO_OVERWRITE       Auto overwrite existing files: true|false (default: false)

Examples:
  # Default setup
  $0

  # Custom organization
  ROOT_CN="Acme Corp Root CA" ORGANIZATION="Acme Corporation" $0

  # RSA keys
  ROOT_KEY_ALG=rsa ROOT_KEY_SIZE=4096 $0

  # Shorter validity for testing
  ROOT_VALIDITY_DAYS=365 $0

  # Auto overwrite without prompting
  AUTO_OVERWRITE=true $0

EOF
}

main() {
    if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
        usage
        exit 0
    fi

    print_info "Root CA Setup Script v${PKI_SETUP_VERSION}"
    echo ""

    check_openssl

    echo "Configuration:"
    echo "  PKI Directory:  $PKI_DIR"
    echo "  Root CN:        $ROOT_CN"
    echo "  Root Validity:  $ROOT_VALIDITY_DAYS days"
    echo "  Root Key:       $ROOT_KEY_ALG ($ROOT_KEY_SIZE)"
    echo "  Create CRL:     $CREATE_CRL"
    echo ""

    check_files_and_prompt "$ROOT_KEY_FILE" "$ROOT_CERT_FILE"

    create_directory_structure
    init_ca_database
    write_root_openssl_config

    generate_root_key
    generate_root_cert
    create_root_crl

    print_summary
}

main "$@"
