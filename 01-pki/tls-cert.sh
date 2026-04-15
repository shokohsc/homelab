#!/usr/bin/env bash
set -euo pipefail

TLS_CERT_VERSION="1.0.1"

: "${PKI_DIR:=./pki}"
: "${OUTPUT_DIR:=${PKI_DIR}/leafs}"
: "${INTERMEDIATE_CERTS_DIR:=${PKI_DIR}/intermediate/certs}"
: "${INTERMEDIATE_PRIVATE_DIR:=${PKI_DIR}/intermediate/private}"
: "${INTERMEDIATE_CERT_FILE:=${INTERMEDIATE_CERTS_DIR}/ca.intermediate.crt.pem}"
: "${INTERMEDIATE_CERT_LOCATION:=file}"
: "${INTERMEDIATE_CERT_PATH:=}"
: "${INTERMEDIATE_CERT_PKCS11_URI:=}"
: "${INTERMEDIATE_KEY_FILE:=${INTERMEDIATE_PRIVATE_DIR}/ca.intermediate.key.pem}"
: "${INTERMEDIATE_KEY_LOCATION:=file}"
: "${INTERMEDIATE_KEY_PATH:=}"
: "${INTERMEDIATE_KEY_PKCS11_URI:=}"
: "${INTERMEDIATE_KEY_PKCS11_MODULE:=}"
: "${ROOT_CERT_FILE:=${PKI_DIR}/root/certs/ca.root.crt.pem}"
: "${INTERMEDIATE_CRL_FILE:=${INTERMEDIATE_CERTS_DIR}/../crl/intermediate.crl.pem}"
: "${CHAIN_BUNDLE_FILE:=${INTERMEDIATE_CERTS_DIR}/ca.chain.crt.pem}"

: "${CERT_CN:=example.com}"
: "${CERT_SAN:=${CERT_CN}}"
: "${CERT_VALIDITY_DAYS:=365}"
: "${CERT_KEY_ALG:=ec}"
: "${CERT_KEY_SIZE:=prime256v1}"
: "${OUTPUT_FORMATS:=crt,pem,der,pfx}"
: "${CREATE_CRL:=true}"
: "${CREATE_OCSP_REQUEST:=true}"

: "${COUNTRY:=US}"
: "${STATE:=State}"
: "${LOCALITY:=City}"
: "${ORGANIZATION:=Organization}"
: "${ORGANIZATIONAL_UNIT:=IT}"
: "${EMAIL:=server@example.com}"
: "${AUTO_OVERWRITE:=false}"

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

check_dependencies() {
    case "$INTERMEDIATE_CERT_LOCATION" in
        file)
            INTERMEDIATE_CERT_FILE="${INTERMEDIATE_CERT_PATH:-${INTERMEDIATE_CERTS_DIR}/ca.intermediate.crt.pem}"
            if [[ ! -f "$INTERMEDIATE_CERT_FILE" ]]; then
                print_error "Intermediate certificate not found: $INTERMEDIATE_CERT_FILE"
                print_error "Run pki-setup.sh first"
                exit 1
            fi
            ;;
        pkcs11)
            if [[ -z "$INTERMEDIATE_CERT_PKCS11_URI" ]]; then
                print_error "PKCS#11 URI required when INTERMEDIATE_CERT_LOCATION=pkcs11"
                print_error "Set INTERMEDIATE_CERT_PKCS11_URI environment variable"
                exit 1
            fi
            print_info "Using PKCS#11 certificate at: $INTERMEDIATE_CERT_PKCS11_URI"
            INTERMEDIATE_CERT_FILE="$INTERMEDIATE_CERT_PKCS11_URI"
            ;;
        *)
            print_error "Unknown certificate location: $INTERMEDIATE_CERT_LOCATION"
            print_error "Use 'file' or 'pkcs11'"
            exit 1
            ;;
    esac

    case "$INTERMEDIATE_KEY_LOCATION" in
        file)
            INTERMEDIATE_KEY_FILE="${INTERMEDIATE_KEY_PATH:-${INTERMEDIATE_PRIVATE_DIR}/ca.intermediate.key.pem}"
            if [[ ! -f "$INTERMEDIATE_KEY_FILE" ]]; then
                print_error "Intermediate key not found: $INTERMEDIATE_KEY_FILE"
                print_error "Run pki-setup.sh first"
                exit 1
            fi
            ;;
        pkcs11)
            if [[ -z "$INTERMEDIATE_KEY_PKCS11_URI" ]]; then
                print_error "PKCS#11 URI required when INTERMEDIATE_KEY_LOCATION=pkcs11"
                print_error "Set INTERMEDIATE_KEY_PKCS11_URI environment variable"
                exit 1
            fi
            INTERMEDIATE_KEY_FILE="$INTERMEDIATE_KEY_PKCS11_URI"
            print_info "Using PKCS#11 key at: $INTERMEDIATE_KEY_PKCS11_URI"
            ;;
        *)
            print_error "Unknown key location: $INTERMEDIATE_KEY_LOCATION"
            print_error "Use 'file' or 'pkcs11'"
            exit 1
            ;;
    esac

    if [[ ! -f "$ROOT_CERT_FILE" ]]; then
        print_error "Root certificate not found: $ROOT_CERT_FILE"
        print_error "Run pki-setup.sh first"
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
        print_warn "Some files already exist"
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

sanitize_cn() {
    echo "$1" | sed 's/[^a-zA-Z0-9._-]/_/g'
}

create_openssl_config() {
    local san="$1"
    local config_file="$2"

    cat > "$config_file" << EOF
[req]
default_bits = 2048
prompt = no
default_md = sha256
distinguished_name = dn
req_extensions = v3_req

[dn]
C = ${COUNTRY}
ST = ${STATE}
L = ${LOCALITY}
O = ${ORGANIZATION}
OU = ${ORGANIZATIONAL_UNIT}
CN = ${CERT_CN}
emailAddress = ${EMAIL}

[v3_req]
keyUsage = critical, keyEncipherment, digitalSignature
extendedKeyUsage = serverAuth, clientAuth
basicConstraints = CA:FALSE
subjectKeyIdentifier = hash
subjectAltName = @alt_names

[alt_names]
EOF

    local counter=1
    IFS=',' read -ra SANS <<< "$san"
    for entry in "${SANS[@]}"; do
        entry=$(echo "$entry" | xargs)
        if [[ "$entry" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
            echo "IP.${counter} = ${entry}" >> "$config_file"
        else
            echo "DNS.${counter} = ${entry}" >> "$config_file"
        fi
        ((counter++))
    done
}

generate_private_key() {
    local key_file="$1"
    local key_alg="$2"
    local key_size="$3"

    print_info "Generating private key..."
    case "$key_alg" in
        rsa)
            openssl genrsa -out "$key_file" "$key_size" 2048
            ;;
        ec)
            openssl ecparam -name "$key_size" -genkey -noout -out "$key_file"
            ;;
        *)
            print_error "Unknown key algorithm: $key_alg"
            exit 1
            ;;
    esac
    chmod 400 "$key_file"
    print_info "Private key generated: $key_file"
}

generate_csr() {
    print_info "[+] Checking for PKCS11 openssl provider"
    export PKCS11_MODULE_PATH="/opt/homebrew/lib/libykcs11.dylib"
    export OPENSSL_MODULES="/opt/homebrew/lib/ossl-modules"
    export OPENSSL_CONF="${PKI_DIR}/../openssl-pkcs11.cnf"
    openssl list -providers

    local key_file="$1"
    local csr_file="$2"
    local san="$3"
    local config_file="$4"

    print_info "Generating CSR..."
    create_openssl_config "$san" "$config_file"
    openssl req -new -key "$key_file" -out "$csr_file" -config "$config_file"
    chmod 444 "$csr_file"
    print_info "CSR generated: $csr_file"
}

sign_certificate() {
    local csr_file="$1"
    local cert_file="$2"
    local san="$3"
    local config_file="$4"

    local index_file="${PKI_DIR}/intermediate/index.txt"
    local serial_file="${PKI_DIR}/intermediate/serial"
    local new_certs_dir="${PKI_DIR}/intermediate/newcerts"

    print_info "Signing certificate..."
    cat > "${PKI_DIR}/signingopenssl.cnf" << EOF
[ca]
default_ca = CA_default

[CA_default]
database = ${index_file}
serial = ${serial_file}
new_certs_dir = ${new_certs_dir}
certificate = ${INTERMEDIATE_CERT_FILE}
private_key = ${INTERMEDIATE_KEY_FILE}
default_md = sha256
policy = policy_anything
copy_extensions = copy

[policy_anything]
countryName = optional
stateOrProvinceName = optional
localityName = optional
organizationName = optional
organizationalUnitName = optional
commonName = supplied
emailAddress = optional

[v3_req]
keyUsage = critical, keyEncipherment, digitalSignature
extendedKeyUsage = serverAuth, clientAuth
basicConstraints = CA:FALSE
subjectKeyIdentifier = hash
subjectAltName = @alt_names

[alt_names]
EOF

    local counter=1
    IFS=',' read -ra SANS <<< "$san"
    for entry in "${SANS[@]}"; do
        entry=$(echo "$entry" | xargs)
        if [[ "$entry" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
            echo "IP.${counter} = ${entry}" >> "${PKI_DIR}/signingopenssl.cnf"
        else
            echo "DNS.${counter} = ${entry}" >> "${PKI_DIR}/signingopenssl.cnf"
        fi
        ((counter++))
    done

    [[ ! -f "$index_file" ]] && touch "$index_file"
    [[ ! -f "$serial_file" ]] && echo "01" > "$serial_file"

    case "$INTERMEDIATE_KEY_LOCATION" in
        pkcs11)
            print_info "Using PKCS#11 for signing..."
            if [[ -n "$INTERMEDIATE_KEY_PKCS11_MODULE" ]]; then
                export PKCS11_MODULE_PATH="$INTERMEDIATE_KEY_PKCS11_MODULE"
            fi
            export OPENSSL_CONF="${PKI_DIR}/../openssl-pkcs11.cnf"
            openssl list -providers 2>/dev/null | grep -i pkcs11 || true
            ;;
    esac

    openssl ca -batch -config "${PKI_DIR}/signingopenssl.cnf" \
        -extensions v3_req \
        -days "$CERT_VALIDITY_DAYS" \
        -in "$csr_file" \
        -out "$cert_file" \
        -notext

    chmod 444 "$cert_file"
    print_info "Certificate signed: $cert_file"
}

verify_certificate() {
    local cert_file="$1"
    print_info "Verifying certificate from Intermediate CA..."

    if [[ -f "$CHAIN_BUNDLE_FILE" ]]; then
        if openssl verify -CAfile "$ROOT_CERT_FILE" -untrusted "$CHAIN_BUNDLE_FILE" "$cert_file"; then
            print_info "Verification successful: Certificate is valid"
        else
            print_error "Verification failed: Certificate is NOT valid"
            exit 1
        fi
    else
        if openssl verify -CAfile "$ROOT_CERT_FILE" "$cert_file"; then
            print_info "Verification successful: Certificate is valid"
        else
            print_error "Verification failed: Certificate is NOT valid"
            exit 1
        fi
    fi
}

export_formats() {
    local cert_file="$1"
    local key_file="$2"
    local output_name="$3"
    local formats_dir="$4"

    print_info "Exporting certificate in multiple formats..."

    IFS=',' read -ra FORMATS <<< "$OUTPUT_FORMATS"
    for fmt in "${FORMATS[@]}"; do
        fmt=$(echo "$fmt" | xargs | tr '[:upper:]' '[:lower:]')
        case "$fmt" in
            crt|pem)
                if [[ "$fmt" == "pem" || -z "${formats_to_create:-}" ]]; then
                    local pem_file="${formats_dir}/${output_name}.crt.pem"
                    if prompt_override "$pem_file"; then
                        cp "$cert_file" "$pem_file"
                        chmod 444 "$pem_file"
                        print_info "  PEM format: $pem_file"
                    fi
                fi
                ;;
            der)
                local der_file="${formats_dir}/${output_name}.crt.der"
                if prompt_override "$der_file"; then
                    openssl x509 -in "$cert_file" -outform DER -out "$der_file"
                    chmod 444 "$der_file"
                    print_info "  DER format: $der_file"
                fi
                ;;
            pfx|p12)
                local pfx_file="${formats_dir}/${output_name}.pfx"
                if prompt_override "$pfx_file"; then
                    openssl pkcs12 -export \
                        -in "$cert_file" \
                        -inkey "$key_file" \
                        -out "$pfx_file" \
                        -name "$output_name" \
                        -password pass:""
                    chmod 400 "$pfx_file"
                    print_info "  PFX format: $pfx_file"
                fi
                ;;
            *)
                print_warn "Unknown format: $fmt"
                ;;
        esac
    done
}

create_fullchain_bundle() {
    local cert_file="$1"
    local bundle_dir="$2"
    local output_name="$3"

    print_info "Creating full chain bundle..."

    local chain_bundle="${bundle_dir}/${output_name}.chain.pem"
    local fullchain_bundle="${bundle_dir}/${output_name}.fullchain.pem"

    if prompt_override "$chain_bundle"; then
        cat "$cert_file" > "$chain_bundle"
        if [[ -f "$CHAIN_BUNDLE_FILE" ]]; then
            cat "$CHAIN_BUNDLE_FILE" >> "$chain_bundle"
        else
            cat "$INTERMEDIATE_CERT_FILE" "$ROOT_CERT_FILE" >> "$chain_bundle"
        fi
        chmod 444 "$chain_bundle"
        print_info "  Chain bundle: $chain_bundle"
    fi

    if prompt_override "$fullchain_bundle"; then
        cat "$cert_file" "$key_file" > "$fullchain_bundle" 2>/dev/null || cat "$cert_file" > "$fullchain_bundle"
        if [[ -f "$CHAIN_BUNDLE_FILE" ]]; then
            cat "$CHAIN_BUNDLE_FILE" >> "$fullchain_bundle"
        else
            cat "$INTERMEDIATE_CERT_FILE" "$ROOT_CERT_FILE" >> "$fullchain_bundle"
        fi
        chmod 444 "$fullchain_bundle"
        print_info "  Full chain bundle: $fullchain_bundle"
    fi
}

create_crl() {
    local cert_file="$1"
    local crl_dir="$2"

    if [[ "$CREATE_CRL" != "true" ]]; then
        return
    fi

    print_info "Creating CRL for certificate..."

    local index_file="${PKI_DIR}/intermediate/index.txt"
    local serial_file="${PKI_DIR}/intermediate/serial"
    local new_certs_dir="${PKI_DIR}/intermediate/newcerts"

    local serial=$(openssl x509 -in "$cert_file" -noout -serial | cut -d'=' -f2)
    local cert_hash=$(openssl x509 -in "$cert_file" -noout -hash)

    if grep -q "/CN=$CERT_CN" "$index_file" 2>/dev/null; then
        :
    fi

    local serial_hex=$(openssl x509 -in "$cert_file" -noout -serial | cut -d'=' -f2 | tr '[:upper:]' '[:lower:]')

    local crl_file="${crl_dir}/${cert_hash}.crl"
    if prompt_override "$crl_file"; then
        cat > "${PKI_DIR}/crl_openssl.cnf" << EOF
[ca]
default_ca = CA_default

[CA_default]
database = ${index_file}
serial = ${serial_file}
new_certs_dir = ${new_certs_dir}
certificate = ${INTERMEDIATE_CERT_FILE}
private_key = ${INTERMEDIATE_KEY_FILE}
default_md = sha256
default_crl_days = 30
EOF
        openssl ca -batch -config "${PKI_DIR}/crl_openssl.cnf" -gencrl -out "$crl_file" 2>&1 || true
        if [[ -f "$crl_file" ]]; then
            chmod 444 "$crl_file"
            print_info "  CRL created: $crl_file"
            openssl crl -in "$crl_file" -inform PEM -noout -text 2>/dev/null | head -10 || true
        else
            print_warn "  Could not create CRL"
        fi
    fi
}

create_ocsp_request() {
    local cert_file="$1"
    local ocsp_dir="$2"
    local output_name="$3"

    if [[ "$CREATE_OCSP_REQUEST" != "true" ]]; then
        return
    fi

    print_info "Creating OCSP request..."

    local ocsp_req_file="${ocsp_dir}/${output_name}.ocsp.req"
    local ocsp_resp_file="${ocsp_dir}/${output_name}.ocsp.resp"

    mkdir -p "$ocsp_dir"

    if prompt_override "$ocsp_req_file"; then
        openssl ocsp \
            -no_nonce \
            -reqout "$ocsp_req_file" \
            -issuer "$INTERMEDIATE_CERT_FILE" \
            -cert "$cert_file" 2>/dev/null || print_warn "Could not create OCSP request"

        if [[ -f "$ocsp_req_file" ]]; then
            chmod 444 "$ocsp_req_file"
            print_info "  OCSP request created: $ocsp_req_file"
        fi

        if [[ -f "$INTERMEDIATE_CERTS_DIR/ocsp.intermediate.crt.pem" && -f "$INTERMEDIATE_CERTS_DIR/../private/ocsp.key.pem" ]]; then
            local ocsp_index_file="${PKI_DIR}/intermediate/index.txt"
            openssl ocsp \
                -index "$ocsp_index_file" \
                -CA "$INTERMEDIATE_CERT_FILE" \
                -rkey "$INTERMEDIATE_CERTS_DIR/../private/ocsp.key.pem" \
                -rsigner "$INTERMEDIATE_CERTS_DIR/ocsp.intermediate.crt.pem" \
                -reqin "$ocsp_req_file" \
                -respout "$ocsp_resp_file" \
                2>/dev/null && print_info "  OCSP response created: $ocsp_resp_file" || print_warn "Could not generate OCSP response"
        fi
    fi
}

display_certificate_info() {
    local cert_file="$1"
    print_info "Certificate Information:"
    openssl x509 -in "$cert_file" -noout -subject -issuer -dates -serial
    echo ""
    print_info "Subject Alternative Names:"
    openssl x509 -in "$cert_file" -noout -text | grep -A1 "Subject Alternative Name" || echo "  None"
}

generate_certificate() {
    local cert_name="$1"
    local san="$2"

    local sanitized_name=$(sanitize_cn "$cert_name")
    local cert_dir="${OUTPUT_DIR}/${sanitized_name}"
    local private_dir="${cert_dir}/private"
    local certs_dir="${cert_dir}/certs"
    local bundle_dir="${cert_dir}/bundle"
    local ocsp_dir="${cert_dir}/ocsp"
    local crl_dir="${cert_dir}/crl"

    mkdir -p "$private_dir" "$certs_dir" "$bundle_dir" "$ocsp_dir" "$crl_dir"
    chmod 755 "$cert_dir" 2>/dev/null || true
    chmod 700 "$private_dir" 2>/dev/null || true
    chmod 755 "$certs_dir" 2>/dev/null || true
    chmod 755 "$bundle_dir" 2>/dev/null || true
    chmod 755 "$ocsp_dir" 2>/dev/null || true
    chmod 755 "$crl_dir" 2>/dev/null || true

    local key_file="${private_dir}/${sanitized_name}.key.pem"
    local csr_file="${certs_dir}/${sanitized_name}.csr.pem"
    local cert_file="${certs_dir}/${sanitized_name}.crt.pem"
    local config_file="${cert_dir}/openssl.cnf"
    local output_name="$sanitized_name"

    echo ""
    echo "=============================================="
    print_info "Generating certificate: $cert_name"
    echo "=============================================="

    local existing_files=("$key_file" "$csr_file" "$cert_file")
    check_files_and_prompt "${existing_files[@]}"

    generate_private_key "$key_file" "$CERT_KEY_ALG" "$CERT_KEY_SIZE"
    generate_csr "$key_file" "$csr_file" "$san" "$config_file"
    sign_certificate "$csr_file" "$cert_file" "$san" "$config_file"

    echo ""
    print_info "Running verification commands..."
    verify_certificate "$cert_file"

    # export_formats "$cert_file" "$key_file" "$output_name" "$certs_dir"
    create_fullchain_bundle "$cert_file" "$bundle_dir" "$output_name"
    create_crl "$cert_file" "$crl_dir"
    create_ocsp_request "$cert_file" "$ocsp_dir" "$output_name"
    display_certificate_info "$cert_file"

    rm -f "$csr_file"

    echo ""
    print_info "Certificate files for $cert_name:"
    echo "  Private key:     $key_file"
    echo "  Certificate:     $cert_file"
    echo "  Formats:         ${OUTPUT_FORMATS}"
    echo "  Chain bundle:    $bundle_dir/${output_name}.chain.pem"
    echo "  Full chain:      $bundle_dir/${output_name}.fullchain.pem"
    echo ""
}

usage() {
    cat << EOF
TLS Certificate Generation Script v${TLS_CERT_VERSION}

Usage: $0 [cert_name] [options]

Positional Arguments:
  cert_name    Common Name for the certificate (required)

Environment Variables:
  PKI_DIR                    PKI directory (default: ./pki)
  OUTPUT_DIR                 Output directory (default: \${PKI_DIR}/leafs)
  INTERMEDIATE_CERT_LOCATION Certificate location: file|pkcs11 (default: file)
  INTERMEDIATE_CERT_PATH     Path to intermediate CA certificate (file mode)
  INTERMEDIATE_CERT_PKCS11_URI PKCS#11 URI for certificate (pkcs11 mode)
  INTERMEDIATE_KEY_LOCATION  Key location: file|pkcs11 (default: file)
  INTERMEDIATE_KEY_PATH      Path to intermediate CA key (file mode)
  INTERMEDIATE_KEY_PKCS11_URI PKCS#11 URI for key (pkcs11 mode)
  INTERMEDIATE_KEY_PKCS11_MODULE PKCS#11 module path (pkcs11 mode)
  ROOT_CERT_FILE             Path to root CA certificate
  CHAIN_BUNDLE_FILE          Path to CA chain bundle

  CERT_CN                    Certificate Common Name (default: example.com)
  CERT_SAN                   Subject Alternate Names, comma-separated (default: same as CERT_CN)
  CERT_VALIDITY_DAYS         Certificate validity in days (default: 365)
  CERT_KEY_ALG               Key algorithm: rsa|ec (default: ec)
  CERT_KEY_SIZE              Key size: for RSA: 2048|4096, for EC: prime256v1|secp384r1 (default: prime256v1)

  OUTPUT_FORMATS             Comma-separated formats: crt,pem,der,pfx (default: crt,pem,der,pfx)
  CREATE_CRL                 Create CRL: true|false (default: true)
  CREATE_OCSP_REQUEST        Create OCSP request: true|false (default: true)

  COUNTRY                    Country code (default: US)
  STATE                      State/Province (default: State)
  LOCALITY                   City/Locality (default: City)
  ORGANIZATION               Organization name (default: Organization)
  ORGANIZATIONAL_UNIT        Organizational Unit (default: IT)
  EMAIL                      Email address (default: server@example.com)

  AUTO_OVERWRITE             Auto overwrite existing files: true|false (default: false)

Examples:
  # Single certificate (using filesystem key)
  $0 example.com

  # With SANs
  CERT_CN=example.com CERT_SAN="example.com,www.example.com,192.168.1.1" $0

  # Multiple SANs
  CERT_SAN="example.com,www.example.com,api.example.com,10.0.0.1" $0

  # Using RSA keys
  CERT_KEY_ALG=rsa CERT_KEY_SIZE=4096 $0 example.com

  # Multiple certificates
  $0 example.com
  CERT_CN="api.example.com" CERT_SAN="api.example.com,*.api.example.com" $0
  CERT_CN="int.example.com" CERT_SAN="int.example.com,internal.example.com" $0

  # Using YubiKey for key (certificate on filesystem)
  INTERMEDIATE_KEY_LOCATION=pkcs11 \\
  INTERMEDIATE_KEY_PKCS11_URI="pkcs11:type=private;object=Intermediate%20CA;type=cert" \\
  INTERMEDIATE_KEY_PKCS11_MODULE=/usr/lib/opensc-pkcs11.so \\
  $0 example.com

  # Using YubiKey with slot identifier for key
  INTERMEDIATE_KEY_LOCATION=pkcs11 \\
  INTERMEDIATE_KEY_PKCS11_URI="pkcs11:type=private;id=%01;object=Intermediate-CA" \\
  $0 example.com

  # Using YubiKey for BOTH certificate and key
  INTERMEDIATE_CERT_LOCATION=pkcs11 \\
  INTERMEDIATE_CERT_PKCS11_URI="pkcs11:type=cert;object=Intermediate%20CA" \\
  INTERMEDIATE_KEY_LOCATION=pkcs11 \\
  INTERMEDIATE_KEY_PKCS11_URI="pkcs11:type=private;object=Intermediate%20CA" \\
  $0 example.com

EOF
}

main() {
    if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
        usage
        exit 0
    fi

    if [[ $# -lt 1 ]]; then
        print_error "Certificate name (Common Name) is required"
        usage
        exit 1
    fi

    CERT_CN="${1:-$CERT_CN}"
    : "${CERT_SAN:=$CERT_CN}"

    print_info "TLS Certificate Generation Script v${TLS_CERT_VERSION}"
    echo ""

    check_openssl
    check_dependencies

    echo "Configuration:"
    echo "  PKI Directory:           $PKI_DIR"
    echo "  Output Directory:       $OUTPUT_DIR"
    echo "  Intermediate Cert Loc:   $INTERMEDIATE_CERT_LOCATION"
    if [[ "$INTERMEDIATE_CERT_LOCATION" == "pkcs11" ]]; then
        echo "  Intermediate Cert URI:   $INTERMEDIATE_CERT_PKCS11_URI"
    fi
    echo "  Intermediate Key Loc:    $INTERMEDIATE_KEY_LOCATION"
    if [[ "$INTERMEDIATE_KEY_LOCATION" == "pkcs11" ]]; then
        echo "  Intermediate Key URI:    $INTERMEDIATE_KEY_PKCS11_URI"
    fi
    echo "  Common Name:            $CERT_CN"
    echo "  SAN(s):                 $CERT_SAN"
    echo "  Validity:               $CERT_VALIDITY_DAYS days"
    echo "  Key Algorithm:          $CERT_KEY_ALG ($CERT_KEY_SIZE)"
    echo "  Output Formats:         $OUTPUT_FORMATS"
    echo ""

    generate_certificate "$CERT_CN" "$CERT_SAN"

    echo ""
    echo "=============================================="
    print_info "TLS Certificate Generation Complete"
    echo "=============================================="
}

main "$@"
