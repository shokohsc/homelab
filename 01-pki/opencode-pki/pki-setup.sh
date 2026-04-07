#!/bin/bash
set -euo pipefail

PKI_SETUP_VERSION="1.0.0"

: "${PKI_DIR:=./pki}"
: "${ROOT_CN:=My Root CA}"
: "${ROOT_VALIDITY_DAYS:=3650}"
: "${ROOT_KEY_ALG:=ec}"
: "${ROOT_KEY_SIZE:=prime256v1}"
: "${INTERMEDIATE_CN:=My Intermediate CA}"
: "${INTERMEDIATE_VALIDITY_DAYS:=1825}"
: "${INTERMEDIATE_KEY_ALG:=ec}"
: "${INTERMEDIATE_KEY_SIZE:=prime256v1}"
: "${INTERMEDIATE_KEY_LOCATION:=file}"
: "${INTERMEDIATE_KEY_PATH:=}"
: "${INTERMEDIATE_PKCS11_URI:=}"
: "${COUNTRY:=US}"
: "${STATE:=State}"
: "${LOCALITY:=City}"
: "${ORGANIZATION:=Organization}"
: "${ORGANIZATIONAL_UNIT:=IT}"
: "${EMAIL:=ca@example.com}"
: "${AUTO_OVERWRITE:=false}"
: "${CREATE_CRL:=true}"
: "${CREATE_OCSP_RESPONDER:=false}"

ROOT_DIR="${PKI_DIR}/root"
ROOT_PRIVATE_DIR="${ROOT_DIR}/private"
ROOT_CERTS_DIR="${ROOT_DIR}/certs"
ROOT_CRL_DIR="${ROOT_DIR}/crl"
ROOT_SERIAL_FILE="${ROOT_DIR}/serial"
ROOT_INDEX_FILE="${ROOT_DIR}/index.txt"
ROOT_NEWCERTS_DIR="${ROOT_DIR}/newcerts"

INTERMEDIATE_DIR="${PKI_DIR}/intermediate"
INTERMEDIATE_PRIVATE_DIR="${INTERMEDIATE_DIR}/private"
INTERMEDIATE_CERTS_DIR="${INTERMEDIATE_DIR}/certs"
INTERMEDIATE_CRL_DIR="${INTERMEDIATE_DIR}/crl"
INTERMEDIATE_CSR_DIR="${INTERMEDIATE_DIR}/csr"
INTERMEDIATE_NEWCERTS_DIR="${INTERMEDIATE_DIR}/newcerts"
INTERMEDIATE_SERIAL_FILE="${INTERMEDIATE_DIR}/serial"
INTERMEDIATE_INDEX_FILE="${INTERMEDIATE_DIR}/index.txt"

ROOT_KEY_FILE="${ROOT_PRIVATE_DIR}/ca.root.key.pem"
ROOT_CERT_FILE="${ROOT_CERTS_DIR}/ca.root.crt.pem"
ROOT_CSR_FILE="${INTERMEDIATE_CSR_DIR}/intermediate.csr.pem"
INTERMEDIATE_KEY_FILE="${INTERMEDIATE_PRIVATE_DIR}/ca.intermediate.key.pem"
INTERMEDIATE_CERT_FILE="${INTERMEDIATE_CERTS_DIR}/ca.intermediate.crt.pem"
INTERMEDIATE_CRL_FILE="${INTERMEDIATE_CRL_DIR}/intermediate.crl.pem"
ROOT_CRL_FILE="${ROOT_CRL_DIR}/root.crl.pem"
# ROOT_OCSP_CERT_FILE="${INTERMEDIATE_CERTS_DIR}/ocsp.root.crt.pem"
# INTERMEDIATE_OCSP_CERT_FILE="${INTERMEDIATE_CERTS_DIR}/ocsp.intermediate.crt.pem"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# # Determine the correct in‑place suffix for the platform
# if [[ "$OSTYPE" == "darwin"* ]]; then
#     SED_INPLACE_EXT="-i ''"
# else
#     SED_INPLACE_EXT="-i"
# fi

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

check_file_exists() {
    local file="$1"
    if [[ -f "$file" ]]; then
        if [[ "$AUTO_OVERWRITE" == "true" ]]; then
            print_warn "File exists, overwriting: $file"
            return 0
        else
            print_warn "File exists: $file"
            return 1
        fi
    fi
    return 0
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
    print_info "Creating directory structure..."
    mkdir -p "$ROOT_PRIVATE_DIR" "$ROOT_CERTS_DIR" "$ROOT_CRL_DIR" "$ROOT_NEWCERTS_DIR"
    mkdir -p "$INTERMEDIATE_PRIVATE_DIR" "$INTERMEDIATE_CERTS_DIR" "$INTERMEDIATE_CRL_DIR"
    mkdir -p "$INTERMEDIATE_CSR_DIR" "$INTERMEDIATE_NEWCERTS_DIR"
    chmod 700 "$ROOT_PRIVATE_DIR" "$INTERMEDIATE_PRIVATE_DIR"
    print_info "Directory structure created"
}

init_ca_databases() {
    print_info "Initializing CA databases..."
    [[ ! -f "$ROOT_SERIAL_FILE" ]] && echo "01" > "$ROOT_SERIAL_FILE"
    [[ ! -f "$ROOT_INDEX_FILE" ]] && touch "$ROOT_INDEX_FILE"
    [[ ! -f "$INTERMEDIATE_SERIAL_FILE" ]] && echo "01" > "$INTERMEDIATE_SERIAL_FILE"
    [[ ! -f "$INTERMEDIATE_INDEX_FILE" ]] && touch "$INTERMEDIATE_INDEX_FILE"
}

generate_root_key() {
    print_info "Generating Root CA key..."
    if prompt_override "$ROOT_KEY_FILE"; then
        local key_args=""
        case "$ROOT_KEY_ALG" in
            rsa)
                key_args="genrsa -out \"$ROOT_KEY_FILE\" $ROOT_KEY_SIZE"
                ;;
            ec)
                key_args="ecparam -name $ROOT_KEY_SIZE -genkey -out \"$ROOT_KEY_FILE\""
                ;;
            *)
                print_error "Unknown key algorithm: $ROOT_KEY_ALG"
                exit 1
                ;;
        esac
        eval openssl "$key_args"
        chmod 400 "$ROOT_KEY_FILE"
        print_info "Root CA key generated: $ROOT_KEY_FILE"
    fi
}

generate_root_cert() {
    print_info "Generating Root CA certificate..."
    if prompt_override "$ROOT_CERT_FILE"; then
        local subject="/C=${COUNTRY}/ST=${STATE}/L=${LOCALITY}/O=${ORGANIZATION}/OU=${ORGANIZATIONAL_UNIT}/CN=${ROOT_CN}/emailAddress=${EMAIL}"
        cat > "${PKI_DIR}/rootopenssl.cnf" << EOF
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

        openssl req -config "${PKI_DIR}/rootopenssl.cnf" -x509 -new -nodes \
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

generate_intermediate_key() {
    print_info "Generating Intermediate CA key..."
    case "$INTERMEDIATE_KEY_LOCATION" in
        file)
            INTERMEDIATE_KEY_FILE="${INTERMEDIATE_KEY_PATH:-${INTERMEDIATE_PRIVATE_DIR}/ca.intermediate.key.pem}"
            if prompt_override "$INTERMEDIATE_KEY_FILE"; then
                local key_args=""
                case "$INTERMEDIATE_KEY_ALG" in
                    rsa)
                        key_args="genrsa -out \"$INTERMEDIATE_KEY_FILE\" $INTERMEDIATE_KEY_SIZE"
                        ;;
                    ec)
                        key_args="ecparam -name $INTERMEDIATE_KEY_SIZE -genkey -out \"$INTERMEDIATE_KEY_FILE\""
                        ;;
                    *)
                        print_error "Unknown key algorithm: $INTERMEDIATE_KEY_ALG"
                        exit 1
                        ;;
                esac
                eval openssl "$key_args"
                chmod 400 "$INTERMEDIATE_KEY_FILE"
                print_info "Intermediate CA key generated: $INTERMEDIATE_KEY_FILE"
            fi
            ;;
        pkcs11)
            if [[ -z "$INTERMEDIATE_PKCS11_URI" ]]; then
                print_error "PKCS11 URI required when INTERMEDIATE_KEY_LOCATION=pkcs11"
                exit 1
            fi
            print_info "Using PKCS#11 key at: $INTERMEDIATE_PKCS11_URI"
            INTERMEDIATE_KEY_FILE="$INTERMEDIATE_PKCS11_URI"
            ;;
        *)
            print_error "Unknown key location: $INTERMEDIATE_KEY_LOCATION"
            exit 1
            ;;
    esac
}

generate_intermediate_csr() {
    print_info "Generating Intermediate CA CSR..."
    if prompt_override "$ROOT_CSR_FILE"; then
        local subject="/C=${COUNTRY}/ST=${STATE}/L=${LOCALITY}/O=${ORGANIZATION}/OU=${ORGANIZATIONAL_UNIT}/CN=${INTERMEDIATE_CN}/emailAddress=${EMAIL}"
        openssl req -new \
            -key "$INTERMEDIATE_KEY_FILE" \
            -subj "$subject" \
            -out "$ROOT_CSR_FILE"
        chmod 444 "$ROOT_CSR_FILE"
        print_info "Intermediate CA CSR generated: $ROOT_CSR_FILE"
    fi
}

sign_intermediate_cert() {
    print_info "Signing Intermediate CA certificate with Root CA..."
    if prompt_override "$INTERMEDIATE_CERT_FILE"; then
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

        openssl ca -batch -config "${PKI_DIR}/intermediateopenssl.cnf" \
            -extensions v3_intermediate_ca \
            -days "$INTERMEDIATE_VALIDITY_DAYS" \
            -in "$ROOT_CSR_FILE" \
            -out "$INTERMEDIATE_CERT_FILE"
        chmod 444 "$INTERMEDIATE_CERT_FILE"
        rm -f "$ROOT_CSR_FILE"
        print_info "Intermediate CA certificate signed and issued: $INTERMEDIATE_CERT_FILE"
    fi
}

verify_intermediate_from_root() {
    print_info "Verifying Intermediate CA certificate from Root CA..."
    if openssl verify -CAfile "$ROOT_CERT_FILE" "$INTERMEDIATE_CERT_FILE"; then
        print_info "Verification successful: Intermediate CA is valid"
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

create_root_crl() {
    if [[ "$CREATE_CRL" != "true" ]]; then
        return
    fi
    
    print_info "Creating Root CA CRL..."
    if prompt_override "$ROOT_CRL_FILE"; then
        openssl ca -batch \
            -config "${PKI_DIR}/intermediateopenssl.cnf" \
            -notext \
            -gencrl \
            -out "$ROOT_CRL_FILE" \
            2>/dev/null || openssl ca -gencrl \
            -cert "$ROOT_CERT_FILE" \
            -keyfile "$ROOT_KEY_FILE" \
            -out "$ROOT_CRL_FILE" 2>/dev/null || {
            openssl rehash -crl \
                -out "$ROOT_CRL_FILE" \
                "$ROOT_CERT_FILE" \
                "$ROOT_KEY_FILE" 2>/dev/null || true
        }
        
        if [[ -f "$ROOT_CRL_FILE" ]]; then
            chmod 444 "$ROOT_CRL_FILE"
            print_info "Root CA CRL created: $ROOT_CRL_FILE"
            openssl crl -in "$ROOT_CRL_FILE" -inform PEM -noout -text 2>/dev/null | head -10 || true
        else
            print_warn "Could not create Root CA CRL"
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
        
        openssl ca -batch -config "${PKI_DIR}/intermediate_crlopenssl.cnf" \
            -gencrl -out "$INTERMEDIATE_CRL_FILE"
        chmod 444 "$INTERMEDIATE_CRL_FILE"
        print_info "Intermediate CA CRL created: $INTERMEDIATE_CRL_FILE"
        
        openssl crl -in "$INTERMEDIATE_CRL_FILE" -inform PEM -noout -text 2>/dev/null | head -10 || true
    fi
}

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
    
    if prompt_override "$ocsp_root_csr"; then
        openssl req -new -key "$ocsp_key" \
            -subj "/C=${COUNTRY}/ST=${STATE}/L=${LOCALITY}/O=${ORGANIZATION}/OU=OCSP/CN=${ROOT_CN} OCSP Responder" \
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

        openssl ca -batch -config "${PKI_DIR}/ocsp_rootopenssl.cnf" \
            -extensions ocsp_extensions \
            -days 365 \
            -in "$ocsp_root_csr" \
            -out "$ocsp_root_cert"
        chmod 444 "$ocsp_root_cert"
        rm -f "$ocsp_root_csr"
    fi
    
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

print_summary() {
    echo ""
    echo "=============================================="
    echo "PKI Setup Complete"
    echo "=============================================="
    echo ""
    echo "Root CA:"
    echo "  Key:    $ROOT_KEY_FILE"
    echo "  Cert:   $ROOT_CERT_FILE"
    echo "  CRL:    $ROOT_CRL_FILE"
    echo ""
    echo "Intermediate CA:"
    echo "  Key:    $INTERMEDIATE_KEY_FILE"
    echo "  Cert:   $INTERMEDIATE_CERT_FILE"
    echo "  Chain:  ${INTERMEDIATE_CERTS_DIR}/ca.chain.crt.pem"
    echo "  CRL:    $INTERMEDIATE_CRL_FILE"
    echo ""
    echo "Certificate Details:"
    echo "  Root CN:           $ROOT_CN"
    echo "  Root Valid Days:   $ROOT_VALIDITY_DAYS"
    echo "  Root Key Alg:      $ROOT_KEY_ALG ($ROOT_KEY_SIZE)"
    echo ""
    echo "  Intermediate CN:   $INTERMEDIATE_CN"
    echo "  Intermediate Days: $INTERMEDIATE_VALIDITY_DAYS"
    echo "  Intermediate Key:  $INTERMEDIATE_KEY_ALG ($INTERMEDIATE_KEY_SIZE)"
    echo "  Key Location:      $INTERMEDIATE_KEY_LOCATION"
    echo ""
    echo "Run verification:"
    echo "  openssl verify -CAfile ${ROOT_CERT_FILE} ${INTERMEDIATE_CERT_FILE}"
    echo ""
}

usage() {
    cat << EOF
PKI Setup Script v${PKI_SETUP_VERSION}

Usage: $0 [options]

Environment Variables:
  PKI_DIR                    Working directory (default: ./pki)
  
  ROOT_CN                    Root CA Common Name (default: My Root CA)
  ROOT_VALIDITY_DAYS         Root certificate validity in days (default: 3650)
  ROOT_KEY_ALG               Root key algorithm: rsa|ec (default: ec)
  ROOT_KEY_SIZE              Root key size: for RSA: 2048|4096, for EC: prime256v1|secp384r1 (default: prime256v1)
  
  INTERMEDIATE_CN            Intermediate CA Common Name (default: My Intermediate CA)
  INTERMEDIATE_VALIDITY_DAYS Intermediate certificate validity in days (default: 1825)
  INTERMEDIATE_KEY_ALG       Intermediate key algorithm: rsa|ec (default: ec)
  INTERMEDIATE_KEY_SIZE      Intermediate key size (default: prime256v1)
  INTERMEDIATE_KEY_LOCATION  Intermediate key location: file|pkcs11 (default: file)
  INTERMEDIATE_KEY_PATH      Path for intermediate key when using file location
  INTERMEDIATE_PKCS11_URI    PKCS#11 URI for key when using pkcs11 location
  
  COUNTRY                    Country code (default: US)
  STATE                      State/Province (default: State)
  LOCALITY                   City/Locality (default: City)
  ORGANIZATION               Organization name (default: Organization)
  ORGANIZATIONAL_UNIT        Organizational Unit (default: IT)
  EMAIL                      Email address (default: ca@example.com)
  
  CREATE_CRL                 Create CRLs: true|false (default: true)
  CREATE_OCSP_RESPONDER      Create OCSP responder certs: true|false (default: false)
  AUTO_OVERWRITE             Auto overwrite existing files: true|false (default: false)

Examples:
  # Default setup
  $0
  
  # Custom configuration
  PKI_DIR=/tmp/my-pki ROOT_CN="Acme Root CA" INTERMEDIATE_CN="Acme Intermediate CA" $0
  
  # Using YubiKey for intermediate key
  INTERMEDIATE_KEY_LOCATION=pkcs11 \\
  INTERMEDIATE_PKCS11_URI="pkcs11:type=private;object=Intermediate%20CA" $0
  
  # RSA keys
  ROOT_KEY_ALG=rsa ROOT_KEY_SIZE=4096 INTERMEDIATE_KEY_ALG=rsa INTERMEDIATE_KEY_SIZE=2048 $0

EOF
}

main() {
    if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
        usage
        exit 0
    fi
    
    print_info "PKI Setup Script v${PKI_SETUP_VERSION}"
    echo ""
    
    check_openssl
    
    echo "Configuration:"
    echo "  PKI Directory:           $PKI_DIR"
    echo "  Root CN:                 $ROOT_CN"
    echo "  Root Validity:           $ROOT_VALIDITY_DAYS days"
    echo "  Root Key:                $ROOT_KEY_ALG ($ROOT_KEY_SIZE)"
    echo "  Intermediate CN:         $INTERMEDIATE_CN"
    echo "  Intermediate Validity:   $INTERMEDIATE_VALIDITY_DAYS days"
    echo "  Intermediate Key:        $INTERMEDIATE_KEY_ALG ($INTERMEDIATE_KEY_SIZE)"
    echo "  Intermediate Key Loc:   $INTERMEDIATE_KEY_LOCATION"
    echo "  Create CRL:              $CREATE_CRL"
    echo "  Create OCSP:             $CREATE_OCSP_RESPONDER"
    echo ""
    
    check_files_and_prompt "$ROOT_KEY_FILE" "$ROOT_CERT_FILE" "$INTERMEDIATE_KEY_FILE" "$INTERMEDIATE_CERT_FILE"
    
    create_directory_structure
    init_ca_databases
    
    generate_root_key
    generate_root_cert
    generate_intermediate_key
    generate_intermediate_csr
    sign_intermediate_cert
    
    echo ""
    print_info "Running verification commands..."
    verify_intermediate_from_root
    
    create_chain_bundle
    create_root_crl
    create_intermediate_crl
    create_ocsp_certificates
    
    print_summary
}

main "$@"
