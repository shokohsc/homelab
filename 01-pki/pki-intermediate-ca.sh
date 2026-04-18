#!/usr/bin/env bash
set -euo pipefail

PKI_INTERMEDIATE_VERSION="1.0.0"

# ---------------------------------------------------------------------------
# Intermediate CA — environment variables
# ---------------------------------------------------------------------------
: "${PKI_DIR:=./pki}"
: "${INTERMEDIATE_CN:=My Intermediate CA}"
: "${INTERMEDIATE_VALIDITY_DAYS:=1825}"
: "${INTERMEDIATE_KEY_ALG:=ec}"
: "${INTERMEDIATE_KEY_SIZE:=prime256v1}"

# Intermediate CA key location: file | pkcs11
: "${INTERMEDIATE_KEY_LOCATION:=file}"
: "${INTERMEDIATE_KEY_PATH:=}"
: "${INTERMEDIATE_KEY_PKCS11_URI:=}"
: "${INTERMEDIATE_KEY_PKCS11_MODULE:=}"

# Root CA key location used for signing/revoking: file | pkcs11
: "${ROOT_KEY_LOCATION:=file}"
: "${ROOT_KEY_PATH:=}"
: "${ROOT_KEY_PKCS11_URI:=}"
: "${ROOT_KEY_PKCS11_MODULE:=}"

# Root CA certificate location: file | pkcs11 (YubiKey slot)
# When pkcs11, the cert is exported from the YubiKey to a temp file via ykman.
: "${ROOT_CERT_LOCATION:=file}"
: "${ROOT_CERT_PATH:=}"
: "${ROOT_CERT_PKCS11_SLOT:=9d}"  # PIV slot used by pki-yubikey-load.sh for root

: "${COUNTRY:=US}"
: "${STATE:=State}"
: "${LOCALITY:=City}"
: "${ORGANIZATION:=Organization}"
: "${ORGANIZATIONAL_UNIT:=IT}"
: "${EMAIL:=ca@example.com}"
: "${AUTO_OVERWRITE:=false}"
: "${CREATE_CRL:=true}"
: "${CREATE_OCSP_RESPONDER:=false}"

# ---------------------------------------------------------------------------
# Derived paths
# ---------------------------------------------------------------------------
ROOT_DIR="${PKI_DIR}/root"
ROOT_PRIVATE_DIR="${ROOT_DIR}/private"
ROOT_CERTS_DIR="${ROOT_DIR}/certs"
ROOT_CRL_DIR="${ROOT_DIR}/crl"
ROOT_NEWCERTS_DIR="${ROOT_DIR}/newcerts"
ROOT_SERIAL_FILE="${ROOT_DIR}/serial"
ROOT_INDEX_FILE="${ROOT_DIR}/index.txt"

INTERMEDIATE_DIR="${PKI_DIR}/intermediate"
INTERMEDIATE_PRIVATE_DIR="${INTERMEDIATE_DIR}/private"
INTERMEDIATE_CERTS_DIR="${INTERMEDIATE_DIR}/certs"
INTERMEDIATE_CRL_DIR="${INTERMEDIATE_DIR}/crl"
INTERMEDIATE_CSR_DIR="${INTERMEDIATE_DIR}/csr"
INTERMEDIATE_NEWCERTS_DIR="${INTERMEDIATE_DIR}/newcerts"
INTERMEDIATE_SERIAL_FILE="${INTERMEDIATE_DIR}/serial"
INTERMEDIATE_INDEX_FILE="${INTERMEDIATE_DIR}/index.txt"

ROOT_CERT_FILE="${ROOT_CERTS_DIR}/ca.root.crt.pem"  # default; may be overridden by resolve_root_cert()
ROOT_CRL_FILE="${ROOT_CRL_DIR}/root.crl.pem"

# Temp file created when ROOT_CERT_LOCATION=pkcs11 (cleaned up on exit)
_TEMP_ROOT_CERT_FILE=""
INTERMEDIATE_CSR_FILE="${INTERMEDIATE_CSR_DIR}/intermediate.csr.pem"
INTERMEDIATE_CERT_FILE="${INTERMEDIATE_CERTS_DIR}/ca.intermediate.crt.pem"
INTERMEDIATE_CRL_FILE="${INTERMEDIATE_CRL_DIR}/intermediate.crl.pem"

# Resolved at runtime by resolve_root_key / resolve_root_cert / resolve_intermediate_key
ROOT_KEY_FILE=""
INTERMEDIATE_KEY_FILE=""

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

# Clean up any temp files created for PKCS#11 cert extraction
_cleanup() {
    if [[ -n "$_TEMP_ROOT_CERT_FILE" ]] && [[ -f "$_TEMP_ROOT_CERT_FILE" ]]; then
        rm -f "$_TEMP_ROOT_CERT_FILE"
    fi
}
trap _cleanup EXIT

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

# ---------------------------------------------------------------------------
# Key resolution
# ---------------------------------------------------------------------------

resolve_root_key() {
    case "$ROOT_KEY_LOCATION" in
        file)
            ROOT_KEY_FILE="${ROOT_KEY_PATH:-${ROOT_PRIVATE_DIR}/ca.root.key.pem}"
            if [[ ! -f "$ROOT_KEY_FILE" ]]; then
                print_error "Root CA key not found: $ROOT_KEY_FILE"
                print_error "Run pki-root-ca.sh first, or set ROOT_KEY_PATH / ROOT_KEY_LOCATION=pkcs11"
                exit 1
            fi
            print_info "Root CA key: filesystem ($ROOT_KEY_FILE)"
            ;;
        pkcs11)
            if [[ -z "$ROOT_KEY_PKCS11_URI" ]]; then
                print_error "ROOT_KEY_PKCS11_URI is required when ROOT_KEY_LOCATION=pkcs11"
                exit 1
            fi
            ROOT_KEY_FILE="$ROOT_KEY_PKCS11_URI"
            print_info "Root CA key: PKCS#11 ($ROOT_KEY_FILE)"
            ;;
        *)
            print_error "Unknown ROOT_KEY_LOCATION: '$ROOT_KEY_LOCATION'. Use 'file' or 'pkcs11'"
            exit 1
            ;;
    esac
}

# Resolve the root CA certificate — either from the filesystem or from the
# YubiKey. Because openssl ca requires a regular file for the 'certificate'
# field, we export the cert from the YubiKey (via ykman) to a temp file when
# ROOT_CERT_LOCATION=pkcs11.
resolve_root_cert() {
    case "$ROOT_CERT_LOCATION" in
        file)
            ROOT_CERT_FILE="${ROOT_CERT_PATH:-${ROOT_CERTS_DIR}/ca.root.crt.pem}"
            if [[ ! -f "$ROOT_CERT_FILE" ]]; then
                print_error "Root CA certificate not found: $ROOT_CERT_FILE"
                print_error "Run pki-root-ca.sh first, or set ROOT_CERT_PATH / ROOT_CERT_LOCATION=pkcs11"
                exit 1
            fi
            print_info "Root CA cert: filesystem ($ROOT_CERT_FILE)"
            ;;
        pkcs11)
            if ! command -v ykman &>/dev/null; then
                print_error "ykman is required to read the root certificate from the YubiKey"
                print_error "Install: brew install yubikey-manager  OR  apt install yubikey-manager"
                exit 1
            fi
            _TEMP_ROOT_CERT_FILE="$(mktemp /tmp/pki-root-ca-XXXXXX.pem)"
            print_info "Exporting root CA certificate from YubiKey (slot ${ROOT_CERT_PKCS11_SLOT})..."
            ykman piv certificates export "${ROOT_CERT_PKCS11_SLOT}" "$_TEMP_ROOT_CERT_FILE" || {
                rm -f "$_TEMP_ROOT_CERT_FILE"
                _TEMP_ROOT_CERT_FILE=""
                print_error "Failed to export root CA certificate from YubiKey slot ${ROOT_CERT_PKCS11_SLOT}"
                exit 1
            }
            ROOT_CERT_FILE="$_TEMP_ROOT_CERT_FILE"
            print_info "Root CA cert: YubiKey slot ${ROOT_CERT_PKCS11_SLOT} (exported to $ROOT_CERT_FILE)"
            ;;
        *)
            print_error "Unknown ROOT_CERT_LOCATION: '$ROOT_CERT_LOCATION'. Use 'file' or 'pkcs11'"
            exit 1
            ;;
    esac
}

resolve_intermediate_key() {
    case "$INTERMEDIATE_KEY_LOCATION" in
        file)
            INTERMEDIATE_KEY_FILE="${INTERMEDIATE_KEY_PATH:-${INTERMEDIATE_PRIVATE_DIR}/ca.intermediate.key.pem}"
            print_info "Intermediate CA key: filesystem ($INTERMEDIATE_KEY_FILE)"
            ;;
        pkcs11)
            if [[ -z "$INTERMEDIATE_KEY_PKCS11_URI" ]]; then
                print_error "INTERMEDIATE_KEY_PKCS11_URI is required when INTERMEDIATE_KEY_LOCATION=pkcs11"
                exit 1
            fi
            INTERMEDIATE_KEY_FILE="$INTERMEDIATE_KEY_PKCS11_URI"
            print_info "Intermediate CA key: PKCS#11 ($INTERMEDIATE_KEY_FILE)"
            ;;
        *)
            print_error "Unknown INTERMEDIATE_KEY_LOCATION: '$INTERMEDIATE_KEY_LOCATION'. Use 'file' or 'pkcs11'"
            exit 1
            ;;
    esac
}

# ---------------------------------------------------------------------------
# PKCS#11 provider setup
# ---------------------------------------------------------------------------

# Enable the PKCS#11 OpenSSL provider for operations that use a hardware key.
# $1 = "root" | "intermediate"
setup_pkcs11_for() {
    local side="$1"
    local module=""

    case "$side" in
        root)
            [[ "$ROOT_KEY_LOCATION" != "pkcs11" ]] && return
            module="${ROOT_KEY_PKCS11_MODULE:-}"
            ;;
        intermediate)
            [[ "$INTERMEDIATE_KEY_LOCATION" != "pkcs11" ]] && return
            module="${INTERMEDIATE_KEY_PKCS11_MODULE:-}"
            ;;
    esac

    if [[ -n "$module" ]]; then
        export PKCS11_MODULE_PATH="$module"
    fi
    export OPENSSL_MODULES="${OPENSSL_MODULES:-/opt/homebrew/lib/ossl-modules}"
    export OPENSSL_CONF="${PKI_DIR}/../openssl-pkcs11.cnf"
    print_info "PKCS#11 provider configured for $side CA operations"
    openssl list -providers 2>/dev/null | grep -i pkcs11 \
        || print_warn "PKCS#11 provider not listed — verify openssl-pkcs11.cnf"
}

# ---------------------------------------------------------------------------
# Directory & database initialisation
# ---------------------------------------------------------------------------

check_prerequisites() {
    # Root cert is verified after resolve_root_cert() sets ROOT_CERT_FILE.
    # Here we only check the Root CA database which must always be on disk.
    if [[ ! -f "$ROOT_INDEX_FILE" ]]; then
        print_error "Root CA database not found: $ROOT_INDEX_FILE"
        print_error "Run pki-root-ca.sh first"
        exit 1
    fi
}

create_directory_structure() {
    print_info "Creating Intermediate CA directory structure..."
    mkdir -p "$INTERMEDIATE_PRIVATE_DIR" "$INTERMEDIATE_CERTS_DIR" "$INTERMEDIATE_CRL_DIR" \
             "$INTERMEDIATE_CSR_DIR" "$INTERMEDIATE_NEWCERTS_DIR"
    chmod 700 "$INTERMEDIATE_PRIVATE_DIR"
    print_info "Directory structure created"
}

init_ca_database() {
    print_info "Initializing Intermediate CA database..."
    [[ ! -f "$INTERMEDIATE_SERIAL_FILE" ]] && echo "01" > "$INTERMEDIATE_SERIAL_FILE"
    [[ ! -f "$INTERMEDIATE_INDEX_FILE" ]] && touch "$INTERMEDIATE_INDEX_FILE"
}

# ---------------------------------------------------------------------------
# OpenSSL config generation
# ---------------------------------------------------------------------------

# Config used by the ROOT CA to sign the intermediate cert, generate the root
# CRL, and revoke the intermediate cert.  private_key is set to whatever
# ROOT_KEY_FILE resolved to (file path or PKCS#11 URI).
write_root_signing_config() {
    cat > "${PKI_DIR}/intermediateopenssl.cnf" << EOF
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

[v3_intermediate_ca]
basicConstraints = critical, CA:true, pathlen:0
keyUsage = critical, keyCertSign, cRLSign, digitalSignature
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid,issuer
EOF
}

# ---------------------------------------------------------------------------
# Intermediate CA creation
# ---------------------------------------------------------------------------

generate_intermediate_key() {
    print_info "Generating Intermediate CA key..."
    case "$INTERMEDIATE_KEY_LOCATION" in
        file)
            if prompt_override "$INTERMEDIATE_KEY_FILE"; then
                case "$INTERMEDIATE_KEY_ALG" in
                    rsa)
                        openssl genrsa -out "$INTERMEDIATE_KEY_FILE" "$INTERMEDIATE_KEY_SIZE"
                        ;;
                    ec)
                        openssl ecparam -name "$INTERMEDIATE_KEY_SIZE" -genkey -out "$INTERMEDIATE_KEY_FILE"
                        ;;
                    *)
                        print_error "Unknown key algorithm: $INTERMEDIATE_KEY_ALG"
                        exit 1
                        ;;
                esac
                chmod 400 "$INTERMEDIATE_KEY_FILE"
                print_info "Intermediate CA key generated: $INTERMEDIATE_KEY_FILE"
            fi
            ;;
        pkcs11)
            print_info "Skipping key generation — using existing PKCS#11 key: $INTERMEDIATE_KEY_FILE"
            ;;
    esac
}

generate_intermediate_csr() {
    print_info "Generating Intermediate CA CSR..."
    if prompt_override "$INTERMEDIATE_CSR_FILE"; then
        local subject="/C=${COUNTRY}/ST=${STATE}/L=${LOCALITY}/O=${ORGANIZATION}/OU=${ORGANIZATIONAL_UNIT}/CN=${INTERMEDIATE_CN}/emailAddress=${EMAIL}"

        # Enable PKCS#11 if the intermediate key lives on hardware
        setup_pkcs11_for intermediate

        openssl req -new \
            -key "$INTERMEDIATE_KEY_FILE" \
            -subj "$subject" \
            -out "$INTERMEDIATE_CSR_FILE"
        chmod 444 "$INTERMEDIATE_CSR_FILE"
        print_info "Intermediate CA CSR generated: $INTERMEDIATE_CSR_FILE"
    fi
}

sign_intermediate_cert() {
    print_info "Signing Intermediate CA certificate with Root CA..."
    if prompt_override "$INTERMEDIATE_CERT_FILE"; then
        # Enable PKCS#11 if the root key lives on hardware
        setup_pkcs11_for root

        openssl ca -batch -config "${PKI_DIR}/intermediateopenssl.cnf" \
            -extensions v3_intermediate_ca \
            -days "$INTERMEDIATE_VALIDITY_DAYS" \
            -in "$INTERMEDIATE_CSR_FILE" \
            -out "$INTERMEDIATE_CERT_FILE"
        chmod 444 "$INTERMEDIATE_CERT_FILE"
        rm -f "$INTERMEDIATE_CSR_FILE"
        print_info "Intermediate CA certificate signed: $INTERMEDIATE_CERT_FILE"
    fi
}

verify_intermediate() {
    print_info "Verifying Intermediate CA certificate against Root CA..."
    if openssl verify -CAfile "$ROOT_CERT_FILE" "$INTERMEDIATE_CERT_FILE"; then
        print_info "Verification successful"
    else
        print_error "Verification failed: Intermediate CA certificate is NOT valid"
        exit 1
    fi
}

create_chain_bundle() {
    print_info "Creating CA chain bundle..."
    local chain_file="${INTERMEDIATE_CERTS_DIR}/ca.chain.crt.pem"
    if prompt_override "$chain_file"; then
        cat "$INTERMEDIATE_CERT_FILE" "$ROOT_CERT_FILE" > "$chain_file"
        chmod 444 "$chain_file"
        print_info "CA chain bundle created: $chain_file"
    fi
}

# ---------------------------------------------------------------------------
# CRL management
# ---------------------------------------------------------------------------

create_root_crl() {
    if [[ "$CREATE_CRL" != "true" ]]; then
        return
    fi

    print_info "Updating Root CA CRL..."
    if prompt_override "$ROOT_CRL_FILE"; then
        setup_pkcs11_for root

        openssl ca -batch \
            -config "${PKI_DIR}/intermediateopenssl.cnf" \
            -notext \
            -gencrl \
            -out "$ROOT_CRL_FILE" 2>/dev/null || {
            print_warn "Could not update Root CA CRL"
            return
        }

        if [[ -f "$ROOT_CRL_FILE" ]]; then
            chmod 444 "$ROOT_CRL_FILE"
            print_info "Root CA CRL updated: $ROOT_CRL_FILE"
        fi
    fi
}

create_intermediate_crl() {
    if [[ "$CREATE_CRL" != "true" ]]; then
        return
    fi

    print_info "Creating Intermediate CA CRL..."
    if prompt_override "$INTERMEDIATE_CRL_FILE"; then
        cat > "${PKI_DIR}/intermediate_crlopenssl.cnf" << EOF
[ca]
default_ca = CA_default

[CA_default]
database = ${INTERMEDIATE_INDEX_FILE}
serial = ${INTERMEDIATE_SERIAL_FILE}
new_certs_dir = ${INTERMEDIATE_NEWCERTS_DIR}
certificate = ${INTERMEDIATE_CERT_FILE}
private_key = ${INTERMEDIATE_KEY_FILE}
default_md = sha256
default_crl_days = 30
crl_extensions = crl_ext

[crl_ext]
authorityKeyIdentifier = keyid:always
EOF

        # Enable PKCS#11 if the intermediate key lives on hardware
        setup_pkcs11_for intermediate

        openssl ca -batch -config "${PKI_DIR}/intermediate_crlopenssl.cnf" \
            -gencrl -out "$INTERMEDIATE_CRL_FILE"
        chmod 444 "$INTERMEDIATE_CRL_FILE"
        print_info "Intermediate CA CRL created: $INTERMEDIATE_CRL_FILE"
        openssl crl -in "$INTERMEDIATE_CRL_FILE" -inform PEM -noout -text 2>/dev/null | head -10 || true
    fi
}

# ---------------------------------------------------------------------------
# Revocation
# ---------------------------------------------------------------------------

revoke_intermediate_cert() {
    print_info "Revoking Intermediate CA certificate..."

    if [[ ! -f "$INTERMEDIATE_CERT_FILE" ]]; then
        print_error "Intermediate CA certificate not found: $INTERMEDIATE_CERT_FILE"
        exit 1
    fi

    write_root_signing_config
    setup_pkcs11_for root

    openssl ca -config "${PKI_DIR}/intermediateopenssl.cnf" \
        -revoke "$INTERMEDIATE_CERT_FILE"
    print_info "Intermediate CA certificate revoked in Root CA database"

    # Regenerate the Root CRL to publish the revocation
    print_info "Regenerating Root CA CRL..."
    mkdir -p "$ROOT_CRL_DIR"
    openssl ca -batch \
        -config "${PKI_DIR}/intermediateopenssl.cnf" \
        -notext -gencrl \
        -out "$ROOT_CRL_FILE"
    chmod 444 "$ROOT_CRL_FILE"
    print_info "Root CA CRL updated: $ROOT_CRL_FILE"
    print_info "Distribute the updated CRL so relying parties can detect the revocation."
}

# ---------------------------------------------------------------------------
# OCSP responder certificates (optional)
# ---------------------------------------------------------------------------

create_ocsp_certificates() {
    if [[ "$CREATE_OCSP_RESPONDER" != "true" ]]; then
        return
    fi

    print_info "Creating OCSP responder certificates..."

    local ocsp_key="${INTERMEDIATE_PRIVATE_DIR}/ocsp.key.pem"
    local ocsp_root_csr="${INTERMEDIATE_CSR_DIR}/ocsp.root.csr.pem"
    local ocsp_root_cert="${INTERMEDIATE_CERTS_DIR}/ocsp.root.crt.pem"
    local ocsp_intermediate_csr="${INTERMEDIATE_CSR_DIR}/ocsp.intermediate.csr.pem"
    local ocsp_intermediate_cert="${INTERMEDIATE_CERTS_DIR}/ocsp.intermediate.crt.pem"

    if prompt_override "$ocsp_key"; then
        openssl ecparam -name prime256v1 -genkey -noout -out "$ocsp_key"
        chmod 400 "$ocsp_key"
    fi

    # --- Root OCSP responder cert (signed by Root CA) ---
    if prompt_override "$ocsp_root_csr"; then
        openssl req -new -key "$ocsp_key" \
            -subj "/C=${COUNTRY}/ST=${STATE}/L=${LOCALITY}/O=${ORGANIZATION}/OU=OCSP/CN=${ROOT_CN:-Root CA} OCSP Responder" \
            -out "$ocsp_root_csr"
    fi

    if prompt_override "$ocsp_root_cert"; then
        cat > "${PKI_DIR}/ocsp_rootopenssl.cnf" << EOF
[ca]
default_ca = CA_default

[CA_default]
database = ${ROOT_INDEX_FILE}
serial = ${ROOT_SERIAL_FILE}
new_certs_dir = ${ROOT_NEWCERTS_DIR}
certificate = ${ROOT_CERT_FILE}
private_key = ${ROOT_KEY_FILE}
default_md = sha256

[ocsp_extensions]
keyUsage = critical, digitalSignature
extendedKeyUsage = critical, OCSPSigning
basicConstraints = CA:FALSE
EOF
        setup_pkcs11_for root
        openssl ca -batch -config "${PKI_DIR}/ocsp_rootopenssl.cnf" \
            -extensions ocsp_extensions \
            -days 365 \
            -in "$ocsp_root_csr" \
            -out "$ocsp_root_cert"
        chmod 444 "$ocsp_root_cert"
        rm -f "$ocsp_root_csr"
    fi

    # --- Intermediate OCSP responder cert (signed by Intermediate CA) ---
    if prompt_override "$ocsp_intermediate_csr"; then
        openssl req -new -key "$ocsp_key" \
            -subj "/C=${COUNTRY}/ST=${STATE}/L=${LOCALITY}/O=${ORGANIZATION}/OU=OCSP/CN=${INTERMEDIATE_CN} OCSP Responder" \
            -out "$ocsp_intermediate_csr"
    fi

    if prompt_override "$ocsp_intermediate_cert"; then
        cat > "${PKI_DIR}/ocsp_intermediateopenssl.cnf" << EOF
[ca]
default_ca = CA_default

[CA_default]
database = ${INTERMEDIATE_INDEX_FILE}
serial = ${INTERMEDIATE_SERIAL_FILE}
new_certs_dir = ${INTERMEDIATE_NEWCERTS_DIR}
certificate = ${INTERMEDIATE_CERT_FILE}
private_key = ${INTERMEDIATE_KEY_FILE}
default_md = sha256

[ocsp_extensions]
keyUsage = critical, digitalSignature
extendedKeyUsage = critical, OCSPSigning
basicConstraints = CA:FALSE
EOF
        setup_pkcs11_for intermediate
        openssl ca -batch -config "${PKI_DIR}/ocsp_intermediateopenssl.cnf" \
            -extensions ocsp_extensions \
            -days 365 \
            -in "$ocsp_intermediate_csr" \
            -out "$ocsp_intermediate_cert"
        chmod 444 "$ocsp_intermediate_cert"
        rm -f "$ocsp_intermediate_csr"
    fi

    print_info "OCSP responder certificates created"
}

# ---------------------------------------------------------------------------
# Summary & usage
# ---------------------------------------------------------------------------

print_summary() {
    echo ""
    echo "=============================================="
    echo "Intermediate CA Setup Complete"
    echo "=============================================="
    echo ""
    echo "Intermediate CA:"
    echo "  Key:    $INTERMEDIATE_KEY_FILE"
    echo "  Cert:   $INTERMEDIATE_CERT_FILE"
    echo "  Chain:  ${INTERMEDIATE_CERTS_DIR}/ca.chain.crt.pem"
    echo "  CRL:    $INTERMEDIATE_CRL_FILE"
    echo ""
    echo "Certificate Details:"
    echo "  CN:                $INTERMEDIATE_CN"
    echo "  Validity:          $INTERMEDIATE_VALIDITY_DAYS days"
    echo "  Key algorithm:     $INTERMEDIATE_KEY_ALG ($INTERMEDIATE_KEY_SIZE)"
    echo "  Key location:      $INTERMEDIATE_KEY_LOCATION"
    echo "  Root key source:   $ROOT_KEY_LOCATION"
    echo "  Root cert source:  $ROOT_CERT_LOCATION"
    echo ""
    echo "Verify:"
    echo "  openssl verify -CAfile ${ROOT_CERT_FILE} ${INTERMEDIATE_CERT_FILE}"
    echo ""
    echo "Next step — generate leaf TLS certificates:"
    echo "  ./pki-leaf-cert.sh example.com"
    echo ""
}

usage() {
    cat << EOF
Intermediate CA Management Script v${PKI_INTERMEDIATE_VERSION}

Usage: $0 [create|revoke] [options]

Commands:
  create   (default)  Create or renew the Intermediate CA
  revoke              Revoke the current Intermediate CA certificate and
                      refresh the Root CA CRL

Environment Variables:

  Root CA certificate (used as trust anchor and in the signing config):
    ROOT_CERT_LOCATION          file|pkcs11 (default: file)
    ROOT_CERT_PATH              Path to root cert (file mode, default: auto)
    ROOT_CERT_PKCS11_SLOT       YubiKey PIV slot containing the root cert (pkcs11 mode, default: 9d)
                                ykman is required when pkcs11 is chosen.

  Root CA key (needed for signing / revoking / CRL updates):
    ROOT_KEY_LOCATION           file|pkcs11 (default: file)
    ROOT_KEY_PATH               Path to root key (file mode, default: auto)
    ROOT_KEY_PKCS11_URI         PKCS#11 URI for root key (pkcs11 mode)
    ROOT_KEY_PKCS11_MODULE      PKCS#11 module path (pkcs11 mode)

  Intermediate CA key:
    INTERMEDIATE_CN                 Common Name (default: My Intermediate CA)
    INTERMEDIATE_VALIDITY_DAYS      Validity in days (default: 1825)
    INTERMEDIATE_KEY_ALG            rsa|ec (default: ec)
    INTERMEDIATE_KEY_SIZE           prime256v1|secp384r1|2048|4096 (default: prime256v1)
    INTERMEDIATE_KEY_LOCATION       file|pkcs11 (default: file)
    INTERMEDIATE_KEY_PATH           Path to intermediate key (file mode, default: auto)
    INTERMEDIATE_KEY_PKCS11_URI     PKCS#11 URI for intermediate key (pkcs11 mode)
    INTERMEDIATE_KEY_PKCS11_MODULE  PKCS#11 module path (pkcs11 mode)

  Subject fields:
    COUNTRY, STATE, LOCALITY, ORGANIZATION, ORGANIZATIONAL_UNIT, EMAIL

  Misc:
    PKI_DIR                 Working directory (default: ./pki)
    CREATE_CRL              Create CRLs: true|false (default: true)
    CREATE_OCSP_RESPONDER   Create OCSP responder certs: true|false (default: false)
    AUTO_OVERWRITE          Auto overwrite existing files: true|false (default: false)

Examples:
  # Create Intermediate CA — Root CA key on filesystem (default)
  $0

  # Create Intermediate CA — Root CA key AND cert both on filesystem (explicit)
  ROOT_CERT_LOCATION=file ROOT_KEY_LOCATION=file $0

  # Create Intermediate CA — Root CA key on YubiKey, cert on filesystem
  ROOT_KEY_LOCATION=pkcs11 \\
  ROOT_KEY_PKCS11_URI="pkcs11:type=private;object=Root%20CA" \\
  ROOT_KEY_PKCS11_MODULE=/usr/lib/opensc-pkcs11.so \\
  $0

  # Create Intermediate CA — Root CA key AND cert on YubiKey (slot 9d)
  ROOT_CERT_LOCATION=pkcs11 \\
  ROOT_CERT_PKCS11_SLOT=9d \\
  ROOT_KEY_LOCATION=pkcs11 \\
  ROOT_KEY_PKCS11_URI="pkcs11:type=private;object=Root%20CA" \\
  ROOT_KEY_PKCS11_MODULE=/usr/lib/opensc-pkcs11.so \\
  $0

  # Create Intermediate CA — both keys on YubiKey (different slots)
  ROOT_CERT_LOCATION=pkcs11 \\
  ROOT_CERT_PKCS11_SLOT=9d \\
  ROOT_KEY_LOCATION=pkcs11 \\
  ROOT_KEY_PKCS11_URI="pkcs11:type=private;id=%02;object=Root%20CA" \\
  INTERMEDIATE_KEY_LOCATION=pkcs11 \\
  INTERMEDIATE_KEY_PKCS11_URI="pkcs11:type=private;id=%01;object=Intermediate%20CA" \\
  $0

  # Create Intermediate CA — intermediate key on YubiKey, root on filesystem
  INTERMEDIATE_KEY_LOCATION=pkcs11 \\
  INTERMEDIATE_KEY_PKCS11_URI="pkcs11:type=private;object=Intermediate%20CA" \\
  $0

  # Revoke the Intermediate CA — Root CA key on YubiKey, cert on filesystem
  ROOT_KEY_LOCATION=pkcs11 \\
  ROOT_KEY_PKCS11_URI="pkcs11:type=private;object=Root%20CA" \\
  $0 revoke

  # Revoke the Intermediate CA — Root CA key AND cert on YubiKey
  ROOT_CERT_LOCATION=pkcs11 \\
  ROOT_CERT_PKCS11_SLOT=9d \\
  ROOT_KEY_LOCATION=pkcs11 \\
  ROOT_KEY_PKCS11_URI="pkcs11:type=private;object=Root%20CA" \\
  $0 revoke

  # Revoke the Intermediate CA — Root CA key on filesystem
  $0 revoke

  # Custom organization, RSA keys
  INTERMEDIATE_CN="Acme Corp Intermediate CA" \\
  ORGANIZATION="Acme Corporation" \\
  INTERMEDIATE_KEY_ALG=rsa \\
  INTERMEDIATE_KEY_SIZE=2048 \\
  $0

  # Auto overwrite without prompting
  AUTO_OVERWRITE=true $0

EOF
}

# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------

main() {
    local command="${1:-create}"

    if [[ "$command" == "-h" || "$command" == "--help" ]]; then
        usage
        exit 0
    fi

    print_info "Intermediate CA Management Script v${PKI_INTERMEDIATE_VERSION}"
    echo ""

    check_openssl
    resolve_root_key
    resolve_root_cert
    resolve_intermediate_key

    case "$command" in
        create)
            check_prerequisites

            echo "Configuration:"
            echo "  PKI Directory:           $PKI_DIR"
            echo "  Root cert source:        $ROOT_CERT_LOCATION"
            if [[ "$ROOT_CERT_LOCATION" == "pkcs11" ]]; then
                echo "  Root cert YubiKey slot:  $ROOT_CERT_PKCS11_SLOT"
            fi
            echo "  Root key source:         $ROOT_KEY_LOCATION"
            if [[ "$ROOT_KEY_LOCATION" == "pkcs11" ]]; then
                echo "  Root key URI:            $ROOT_KEY_PKCS11_URI"
            fi
            echo "  Intermediate CN:         $INTERMEDIATE_CN"
            echo "  Intermediate Validity:   $INTERMEDIATE_VALIDITY_DAYS days"
            echo "  Intermediate Key:        $INTERMEDIATE_KEY_ALG ($INTERMEDIATE_KEY_SIZE)"
            echo "  Intermediate Key Loc:    $INTERMEDIATE_KEY_LOCATION"
            if [[ "$INTERMEDIATE_KEY_LOCATION" == "pkcs11" ]]; then
                echo "  Intermediate Key URI:    $INTERMEDIATE_KEY_PKCS11_URI"
            fi
            echo "  Create CRL:              $CREATE_CRL"
            echo "  Create OCSP:             $CREATE_OCSP_RESPONDER"
            echo ""

            # Only check filesystem paths (PKCS#11 URIs are not files)
            local files_to_check=()
            [[ "$INTERMEDIATE_KEY_LOCATION" == "file" ]] && files_to_check+=("$INTERMEDIATE_KEY_FILE")
            files_to_check+=("$INTERMEDIATE_CERT_FILE")
            check_files_and_prompt "${files_to_check[@]}"

            create_directory_structure
            init_ca_database
            write_root_signing_config

            generate_intermediate_key
            generate_intermediate_csr
            sign_intermediate_cert

            echo ""
            print_info "Running verification..."
            verify_intermediate

            create_chain_bundle
            create_root_crl
            create_intermediate_crl
            create_ocsp_certificates

            print_summary
            ;;

        revoke)
            echo "Configuration:"
            echo "  PKI Directory:   $PKI_DIR"
            echo "  Root cert source: $ROOT_CERT_LOCATION"
            if [[ "$ROOT_CERT_LOCATION" == "pkcs11" ]]; then
                echo "  Root cert slot:  $ROOT_CERT_PKCS11_SLOT"
            fi
            echo "  Root key source: $ROOT_KEY_LOCATION"
            if [[ "$ROOT_KEY_LOCATION" == "pkcs11" ]]; then
                echo "  Root key URI:    $ROOT_KEY_PKCS11_URI"
            fi
            echo ""

            check_prerequisites
            revoke_intermediate_cert
            ;;

        *)
            print_error "Unknown command: '$command'"
            usage
            exit 1
            ;;
    esac
}

main "$@"
