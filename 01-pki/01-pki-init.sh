#!/usr/bin/env bash
set -euo pipefail

### DEFAULTS ###
BASE_DIR="${PWD}/pki"
DOMAIN="${DOMAIN:-example.domain.tld}"
DAYS_ROOT="${DAYS_ROOT:-3650}"
DAYS_INTERMEDIATE="${DAYS_INTERMEDIATE:-1825}"

FORCE=0

usage() {
  echo "Usage: $0 [-f]"
  exit 1
}

while getopts "f" opt; do
  case $opt in
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
mkdir -p root/{certs,crl,newcerts,private}
mkdir -p intermediate/{certs,crl,csr,newcerts,private,manifests}
chmod 700 root/private intermediate/{private,manifests}

touch root/index.txt intermediate/index.txt
echo 1000 > root/serial
echo 1000 > intermediate/serial

############################
# ROOT CA CONFIG
############################
cat > root/openssl.cnf <<EOF
[ ca ]
default_ca = CA_default

[ CA_default ]
dir               = $BASE_DIR/root
certs             = \$dir/certs
crl_dir           = \$dir/crl
new_certs_dir     = \$dir/newcerts
database          = \$dir/index.txt
serial            = \$dir/serial
private_key       = \$dir/private/root.key.pem
certificate       = \$dir/certs/root.cert.pem
default_md        = sha256
policy            = policy_strict

[ policy_strict ]
commonName = supplied

[ req ]
default_bits        = 4096
prompt              = no
default_md          = sha256
distinguished_name  = dn
x509_extensions     = v3_ca

[ dn ]
CN = Homelab Root CA

[ v3_ca ]
subjectKeyIdentifier=hash
authorityKeyIdentifier=keyid:always
basicConstraints = critical, CA:true
keyUsage = critical, digitalSignature, cRLSign, keyCertSign
EOF

############################
# ROOT CA
############################
echo "[+] Root CA"

warn_if_exists "$BASE_DIR/root/root.key.pem"

openssl genrsa -out root/private/root.key.pem 4096
chmod 600 root/private/root.key.pem

openssl req -config root/openssl.cnf \
    -key root/private/root.key.pem \
    -new -x509 -days $DAYS_ROOT -sha256 \
    -out root/certs/root.cert.pem

############################
# INTERMEDIATE CONFIG
############################
cat > intermediate/openssl.cnf <<EOF
[ ca ]
default_ca = CA_default

[ CA_default ]
dir               = $BASE_DIR/intermediate
certs             = \$dir/certs
crl_dir           = \$dir/crl
new_certs_dir     = \$dir/newcerts
database          = \$dir/index.txt
serial            = \$dir/serial
private_key       = \$dir/private/intermediate.key.pem
certificate       = \$dir/certs/intermediate.cert.pem
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
CN = Homelab Intermediate CA

[ v3_intermediate_ca ]
subjectKeyIdentifier=hash
authorityKeyIdentifier=keyid:always
basicConstraints = critical, CA:true, pathlen:0
keyUsage = critical, digitalSignature, cRLSign, keyCertSign
EOF

############################
# INTERMEDIATE CA
############################
echo "[+] Intermediate CA"

warn_if_exists "$BASE_DIR/intermediate/private/intermediate.key.pem"

openssl genrsa -out intermediate/private/intermediate.key.pem 4096
chmod 400 intermediate/private/intermediate.key.pem

openssl req -config intermediate/openssl.cnf \
    -new -sha256 \
    -key intermediate/private/intermediate.key.pem \
    -out intermediate/csr/intermediate.csr.pem

openssl ca -batch -config root/openssl.cnf \
    -extensions v3_ca \
    -days $DAYS_INTERMEDIATE \
    -in intermediate/csr/intermediate.csr.pem \
    -out intermediate/certs/intermediate.cert.pem

############################
# CHAIN FILE
############################
cat intermediate/certs/intermediate.cert.pem \
    root/certs/root.cert.pem > intermediate/certs/ca-chain.cert.pem

############################
# VERIFICATION
############################
echo "[+] Verifying chain"

openssl verify -CAfile "$BASE_DIR/root/certs/root.cert.pem" \
  "$BASE_DIR/intermediate/certs/intermediate.cert.pem"

echo "[✔] Done!"
echo
echo "Root CA:         root/certs/root.cert.pem"
echo "Intermediate CA: intermediate/certs/intermediate.cert.pem"
echo "Full chain:      intermediate/certs/ca-chain.cert.pem"

############################
# CERT-MANAGER
############################
cat > intermediate/manifests/cert-manager.yaml <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: intermediate-tls
type: kubernetes.io/tls
data:
  tls.crt: $(base64 -w0 < intermediate/certs/ca-chain.cert.pem)
  tls.key: $(base64 -w0 < intermediate/private/intermediate.key.pem)
EOF
