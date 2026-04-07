#!/usr/bin/env bash
set -euo pipefail

### DEFAULTS ###
BASE_DIR="${PWD}/pki"
DOMAIN="${DOMAIN:-example.domain.tld}"
DAYS_SERVER="${DAYS_SERVER:-825}"


usage() {
  echo "Usage: $0 [-d domain] [-f]"
  exit 1
}

while getopts "d:f" opt; do
  case $opt in
    d) DOMAIN="$OPTARG" ;;
    f) FORCE=1 ;;
    *) usage ;;
  esac
done

warn_if_exists() {
  if [[ -e "$1" && "$FORCE" -eq 0 ]]; then
    echo "[!] File exists: $1 (use -f to overwrite)"
    exit 1
  fi
}

mkdir -p "$BASE_DIR"
cd "$BASE_DIR"

echo "[+] Creating directory structure"
mkdir -p server/{certs,crl,csr,newcerts,private,tfvars}
chmod 700 server/{private,tfvars}

############################
# SERVER CONFIG
############################
cat > server/openssl.cnf <<EOF
[ ca ]
default_ca = CA_default

[ CA_default ]
dir               = $BASE_DIR/intermediate
certs             = \$dir/certs
crl_dir           = \$dir/crl
new_certs_dir     = \$dir/newcerts
database          = \$dir/index.txt
serial            = \$dir/serial

private_key       = pkcs11:model=YubiKey%20YK5;manufacturer=Yubico%20%28www.yubico.com%29;serial=29141161;token=YubiKey%20PIV%20%2329141161;id=%02;object=Private%20key%20for%20Digital%20Signature;type=private
certificate       = pkcs11:model=YubiKey%20YK5;manufacturer=Yubico%20%28www.yubico.com%29;serial=29141161;token=YubiKey%20PIV%20%2329141161;id=%02;object=X.509%20Certificate%20for%20Digital%20Signature;type=cert

default_md        = sha256
policy            = policy_loose

[ policy_loose ]
commonName = supplied

[ req ]
default_bits        = 4096
prompt              = no
default_md          = sha256
distinguished_name  = dn

[ dn ]
CN = ${DOMAIN}

[ server_cert ]
basicConstraints = CA:FALSE
nsCertType = server
keyUsage = critical, digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names

[ alt_names ]
DNS.1 = ${DOMAIN}
EOF

############################
# SERVER CERT (DDNS)
############################
echo "[+] Checking for PKCS11 openssl provider"
export PKCS11_MODULE_PATH=/opt/homebrew/lib/libykcs11.dylib
export OPENSSL_CONF=${BASE_DIR}/../openssl-pkcs11.cnf
export OPENSSL_MODULES=/opt/homebrew/lib/ossl-modules
openssl list -providers

echo "[+] Generating server certificate for $DOMAIN"

warn_if_exists "server/private/${DOMAIN}.key.pem"

openssl genrsa -out server/private/${DOMAIN}.key.pem 2048
chmod 400 server/private/${DOMAIN}.key.pem

openssl req -config server/openssl.cnf \
    -new -sha256 \
    -key server/private/${DOMAIN}.key.pem \
    -out server/csr/${DOMAIN}.csr.pem

echo "[+] Sign via YubiKey"

openssl ca -batch -config server/openssl.cnf \
    -extensions server_cert \
    -days $DAYS_SERVER \
    -in server/csr/${DOMAIN}.csr.pem \
    -out server/certs/${DOMAIN}.cert.pem

############################
# FULLCHAIN
############################
cat server/certs/${DOMAIN}.cert.pem \
    intermediate/certs/ca-chain.cert.pem \
    > server/certs/${DOMAIN}.fullchain.pem

############################
# VERIFICATION
############################
echo "[+] Verifying chain"

openssl verify -CAfile intermediate/certs/ca-chain.cert.pem \
  server/certs/${DOMAIN}.cert.pem

############################
# TERRAFORM OUTPUT
############################
cat > server/tfvars/${DOMAIN}.terraform.tfvars <<EOF
tls_cert = <<EOT
$(cat server/certs/${DOMAIN}.fullchain.pem)
EOT

tls_key = <<EOT
$(cat server/private/${DOMAIN}.key.pem)
EOT
EOF

echo "[✔] Done!"
echo
echo "Server cert:     server/certs/${DOMAIN}.cert.pem"
echo "Full chain:      server/certs/${DOMAIN}.fullchain.pem"
echo "Private key:     server/private/${DOMAIN}.key.pem"
