# PKI and TLS Certificate Generation Scripts

Four bash scripts for creating a two-tier PKI infrastructure, optionally loading CA keys and certificates onto a YubiKey, and generating leaf TLS certificates using only OpenSSL.

## Scripts

| Script | Purpose |
|--------|--------|
| `pki-root-ca.sh` | Creates the **Root CA** (filesystem only, no PKCS\#11) |
| `pki-intermediate-ca.sh` | Creates / renews / revokes the **Intermediate CA**; the Root CA key **and cert** can be read from the filesystem **or** a YubiKey (PKCS\#11) |
| `pki-leaf-cert.sh` | Generates leaf **TLS certificates** signed by the Intermediate CA (key/cert on filesystem or YubiKey) |
| `pki-yubikey-load.sh` | Loads the Root CA and/or Intermediate CA keys + certs onto a YubiKey (staged: `root`, `intermediate`, or `all`) |

## Directory Structure

```
pki/
├── root/
│   ├── private/              # Root CA private key (chmod 700)
│   ├── certs/                # Root CA certificate
│   ├── crl/                  # Root CA CRL
│   └── newcerts/             # New certificates directory
├── intermediate/
│   ├── private/              # Intermediate CA private key
│   ├── certs/                # Intermediate CA certificate + chain bundle
│   ├── crl/                  # Intermediate CA CRL
│   ├── csr/                  # Certificate signing requests
│   └── newcerts/             # New certificates directory
└── leafs/
    └── example.com/
        ├── private/          # Leaf private key
        ├── certs/            # Leaf certificate (multiple formats)
        ├── bundle/           # Chain bundles
        ├── crl/              # CRLs
        └── ocsp/             # OCSP requests
```

## Quick Start

### 1. Create the Root CA (filesystem)

```bash
./pki-root-ca.sh
```

### 2. (Optional) Load Root CA onto YubiKey

```bash
PIN_CODE=123456 ./pki-yubikey-load.sh root
```

### 3. Create the Intermediate CA

```bash
# Root CA key and cert on filesystem (default)
./pki-intermediate-ca.sh

# Root CA key and cert both on YubiKey
ROOT_CERT_LOCATION=pkcs11 \
ROOT_CERT_PKCS11_SLOT=9d \
ROOT_KEY_LOCATION=pkcs11 \
ROOT_KEY_PKCS11_URI="pkcs11:type=private;object=Root%20CA" \
ROOT_KEY_PKCS11_MODULE=/usr/lib/opensc-pkcs11.so \
./pki-intermediate-ca.sh
```

### 4. (Optional) Load Intermediate CA onto YubiKey

```bash
PIN_CODE=123456 ./pki-yubikey-load.sh intermediate
```

### 5. Generate a TLS Leaf Certificate

```bash
# Intermediate CA on filesystem (default)
./pki-leaf-cert.sh example.com

# Intermediate CA key on YubiKey
INTERMEDIATE_KEY_LOCATION=pkcs11 \
INTERMEDIATE_KEY_PKCS11_URI="pkcs11:type=private;object=Intermediate%20CA" \
./pki-leaf-cert.sh example.com
```

## pki-root-ca.sh Options

Creates the **Root CA**. No PKCS\#11 or hardware-token logic at this level — the root key is always stored on the filesystem.

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `PKI_DIR` | Working directory | `./pki` |
| `ROOT_CN` | Root CA Common Name | `My Root CA` |
| `ROOT_VALIDITY_DAYS` | Root certificate validity | `3650` (10 years) |
| `ROOT_KEY_ALG` | Root key algorithm (`rsa` or `ec`) | `ec` |
| `ROOT_KEY_SIZE` | Root key size (`prime256v1`, `secp384r1`, `2048`, `4096`) | `prime256v1` |
| `COUNTRY` | Country code | `US` |
| `STATE` | State/Province | `State` |
| `LOCALITY` | City/Locality | `City` |
| `ORGANIZATION` | Organization name | `Organization` |
| `ORGANIZATIONAL_UNIT` | Organizational Unit | `IT` |
| `EMAIL` | Email address | `ca@example.com` |
| `CREATE_CRL` | Create Root CRL (`true`/`false`) | `true` |
| `AUTO_OVERWRITE` | Auto overwrite files (`true`/`false`) | `false` |

### Examples

**Default setup:**
```bash
./pki-root-ca.sh
```

**Custom organization:**
```bash
ROOT_CN="Acme Corp Root CA" \
ORGANIZATION="Acme Corporation" \
./pki-root-ca.sh
```

**RSA keys:**
```bash
ROOT_KEY_ALG=rsa ROOT_KEY_SIZE=4096 ./pki-root-ca.sh
```

**Shorter validity for testing:**
```bash
ROOT_VALIDITY_DAYS=365 ./pki-root-ca.sh
```

**Auto overwrite without prompting:**
```bash
AUTO_OVERWRITE=true ./pki-root-ca.sh
```

### Output Files

- `root/private/ca.root.key.pem` — Root CA private key
- `root/certs/ca.root.crt.pem` — Root CA certificate
- `root/crl/root.crl.pem` — Root CA CRL

---

## pki-intermediate-ca.sh Options

Manages the **Intermediate CA** (create, renew, revoke). The Root CA **key** and **certificate** can each be read from the **filesystem** or from a **YubiKey / PKCS\#11 token**.

### Commands

| Command | Description |
|---------|-------------|
| `create` (default) | Generate the Intermediate CA key, CSR, and certificate |
| `revoke` | Revoke the current Intermediate CA certificate and refresh the Root CA CRL |

### Environment Variables

**Root CA certificate (trust anchor for signing config and verification):**

| Variable | Description | Default |
|----------|-------------|---------|
| `ROOT_CERT_LOCATION` | Root cert source (`file` or `pkcs11`) | `file` |
| `ROOT_CERT_PATH` | Path to root cert (file mode) | auto |
| `ROOT_CERT_PKCS11_SLOT` | YubiKey PIV slot containing the root cert (pkcs11 mode — requires `ykman`) | `9d` |

**Root CA key (needed for signing / revoking / CRL updates):**

| Variable | Description | Default |
|----------|-------------|---------|
| `ROOT_KEY_LOCATION` | Root key source (`file` or `pkcs11`) | `file` |
| `ROOT_KEY_PATH` | Path to root key (file mode) | auto |
| `ROOT_KEY_PKCS11_URI` | PKCS#11 URI for root key (pkcs11 mode) | - |
| `ROOT_KEY_PKCS11_MODULE` | PKCS#11 module path (pkcs11 mode) | - |

**Intermediate CA key:**

| Variable | Description | Default |
|----------|-------------|---------|
| `INTERMEDIATE_CN` | Intermediate CA Common Name | `My Intermediate CA` |
| `INTERMEDIATE_VALIDITY_DAYS` | Intermediate validity | `1825` (5 years) |
| `INTERMEDIATE_KEY_ALG` | Intermediate key algorithm | `ec` |
| `INTERMEDIATE_KEY_SIZE` | Intermediate key size | `prime256v1` |
| `INTERMEDIATE_KEY_LOCATION` | Key location (`file` or `pkcs11`) | `file` |
| `INTERMEDIATE_KEY_PATH` | Path to intermediate key (file mode) | auto-generated |
| `INTERMEDIATE_KEY_PKCS11_URI` | PKCS#11 URI (pkcs11 mode) | - |
| `INTERMEDIATE_KEY_PKCS11_MODULE` | PKCS#11 module path (pkcs11 mode) | - |

**Common subject fields:** `COUNTRY`, `STATE`, `LOCALITY`, `ORGANIZATION`, `ORGANIZATIONAL_UNIT`, `EMAIL`

**Misc:** `PKI_DIR`, `CREATE_CRL`, `CREATE_OCSP_RESPONDER`, `AUTO_OVERWRITE`

### Examples

**Default — everything on filesystem:**
```bash
./pki-intermediate-ca.sh
```

**Root CA key on YubiKey, cert on filesystem:**
```bash
ROOT_KEY_LOCATION=pkcs11 \
ROOT_KEY_PKCS11_URI="pkcs11:type=private;object=Root%20CA" \
ROOT_KEY_PKCS11_MODULE=/usr/lib/opensc-pkcs11.so \
./pki-intermediate-ca.sh
```

**Root CA key AND cert on YubiKey (slot 9d), intermediate key generated on filesystem:**
```bash
ROOT_CERT_LOCATION=pkcs11 \
ROOT_CERT_PKCS11_SLOT=9d \
ROOT_KEY_LOCATION=pkcs11 \
ROOT_KEY_PKCS11_URI="pkcs11:type=private;object=Root%20CA" \
ROOT_KEY_PKCS11_MODULE=/usr/lib/opensc-pkcs11.so \
./pki-intermediate-ca.sh
```

**All on YubiKey (root slot 9d, intermediate slot 9c):**
```bash
ROOT_CERT_LOCATION=pkcs11 \
ROOT_CERT_PKCS11_SLOT=9d \
ROOT_KEY_LOCATION=pkcs11 \
ROOT_KEY_PKCS11_URI="pkcs11:type=private;id=%02;object=Root%20CA" \
INTERMEDIATE_KEY_LOCATION=pkcs11 \
INTERMEDIATE_KEY_PKCS11_URI="pkcs11:type=private;id=%01;object=Intermediate%20CA" \
./pki-intermediate-ca.sh
```

**Revoke — Root CA key AND cert on YubiKey:**
```bash
ROOT_CERT_LOCATION=pkcs11 \
ROOT_CERT_PKCS11_SLOT=9d \
ROOT_KEY_LOCATION=pkcs11 \
ROOT_KEY_PKCS11_URI="pkcs11:type=private;object=Root%20CA" \
./pki-intermediate-ca.sh revoke
```

**Revoke — everything on filesystem:**
```bash
./pki-intermediate-ca.sh revoke
```

**Custom organization, RSA intermediate key:**
```bash
INTERMEDIATE_CN="Acme Corp Intermediate CA" \
ORGANIZATION="Acme Corporation" \
INTERMEDIATE_KEY_ALG=rsa INTERMEDIATE_KEY_SIZE=2048 \
./pki-intermediate-ca.sh
```

### Output Files

- `intermediate/private/ca.intermediate.key.pem` — Intermediate CA key
- `intermediate/certs/ca.intermediate.crt.pem` — Intermediate CA certificate
- `intermediate/certs/ca.chain.crt.pem` — CA chain bundle (Intermediate + Root)
- `intermediate/crl/intermediate.crl.pem` — Intermediate CA CRL
- `root/crl/root.crl.pem` — Root CA CRL (refreshed after signing or revoking)

### Verification

After running, the script automatically verifies:
```bash
openssl verify -CAfile pki/root/certs/ca.root.crt.pem pki/intermediate/certs/ca.intermediate.crt.pem
```

---

## pki-yubikey-load.sh Options

Loads Root CA and/or Intermediate CA **keys and certificates** into a YubiKey PIV application. The two CAs are loaded in separate stages so that the Intermediate CA can be created with its root already on the YubiKey.

### Commands

| Command | Description |
|---------|-------------|
| `root` | Import root CA key + certificate (slot `SLOT_ROOT`) |
| `intermediate` | Import intermediate CA key + certificate (slot `SLOT_INTERMEDIATE`) |
| `all` (default) | Import both |

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `PKI_DIR` | PKI directory | `./pki` |
| `PIN_CODE` | YubiKey PIV PIN | `000000` |
| `SLOT_ROOT` | PIV slot for Root CA | `9d` |
| `SLOT_INTERMEDIATE` | PIV slot for Intermediate CA | `9c` |

### Examples

**Load Root CA only:**
```bash
PIN_CODE=123456 ./pki-yubikey-load.sh root
```

**Load Intermediate CA only (after root is already on YubiKey):**
```bash
PIN_CODE=123456 ./pki-yubikey-load.sh intermediate
```

**Load both at once:**
```bash
PIN_CODE=123456 ./pki-yubikey-load.sh all
```

### Verification

After running, the script automatically verifies:
```bash
ykman piv info
```

---

## pki-leaf-cert.sh Options

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `PKI_DIR` | PKI directory | `./pki` |
| `OUTPUT_DIR` | Output directory for certificates | `${PKI_DIR}/leafs` |
| `INTERMEDIATE_CERT_LOCATION` | Certificate location (`file` or `pkcs11`) | `file` |
| `INTERMEDIATE_CERT_PATH` | Path to intermediate cert (file mode) | auto |
| `INTERMEDIATE_CERT_PKCS11_URI` | PKCS#11 URI for cert (pkcs11 mode) | - |
| `INTERMEDIATE_KEY_LOCATION` | Key location (`file` or `pkcs11`) | `file` |
| `INTERMEDIATE_KEY_PATH` | Path to intermediate key (file mode) | auto |
| `INTERMEDIATE_KEY_PKCS11_URI` | PKCS#11 URI for key (pkcs11 mode) | - |
| `INTERMEDIATE_KEY_PKCS11_MODULE` | PKCS#11 module path (pkcs11 mode) | - |
| `ROOT_CERT_FILE` | Root CA certificate path | auto |
| `CHAIN_BUNDLE_FILE` | CA chain bundle path | auto |
| `CERT_CN` | Certificate Common Name | `example.com` |
| `CERT_SAN` | Subject Alternative Names (comma-separated) | same as CERT_CN |
| `CERT_VALIDITY_DAYS` | Certificate validity | `365` |
| `CERT_KEY_ALG` | Key algorithm (`rsa` or `ec`) | `ec` |
| `CERT_KEY_SIZE` | Key size | `prime256v1` |
| `OUTPUT_FORMATS` | Output formats (crt,pem,der,pfx) | `crt,pem,der,pfx` |
| `CREATE_CRL` | Create CRL | `true` |
| `CREATE_OCSP_REQUEST` | Create OCSP request | `true` |
| `COUNTRY`, `STATE`, etc. | Subject components | same as pki-root-ca |
| `AUTO_OVERWRITE` | Auto overwrite | `false` |

### Commands

| Command | Description |
|---------|-------------|
| `cert_name` (positional) | Generate a leaf certificate for the given Common Name |
| `revoke cert_name` | Revoke a leaf certificate and regenerate the CRL |

### Examples

**Basic certificate:**
```bash
./pki-leaf-cert.sh example.com
```

**With SANs:**
```bash
CERT_SAN="example.com,www.example.com,api.example.com" \
./pki-leaf-cert.sh example.com
```

**Revoke a leaf certificate:**
```bash
./pki-leaf-cert.sh revoke example.com
```

**IP addresses in SANs:**
```bash
CERT_SAN="example.com,192.168.1.1,10.0.0.1" \
./pki-leaf-cert.sh example.com
```

**Wildcard certificate:**
```bash
CERT_CN="*.example.com" \
CERT_SAN="example.com,*.example.com" \
./pki-leaf-cert.sh wildcard
```

**RSA key:**
```bash
CERT_KEY_ALG=rsa CERT_KEY_SIZE=4096 \
./pki-leaf-cert.sh example.com
```

**Custom output directory:**
```bash
OUTPUT_DIR="/etc/ssl/private" \
./pki-leaf-cert.sh example.com
```

**Only PEM and PFX output:**
```bash
OUTPUT_FORMATS="pem,pfx" \
./pki-leaf-cert.sh example.com
```

**Multiple certificates:**
```bash
./pki-leaf-cert.sh example.com
CERT_CN="api.example.com" CERT_SAN="api.example.com" ./pki-leaf-cert.sh api
CERT_CN="internal.local" CERT_SAN="internal.local,192.168.1.10" ./pki-leaf-cert.sh internal
```

**Using YubiKey for Intermediate CA key signing (PKCS#11):**
```bash
INTERMEDIATE_KEY_LOCATION=pkcs11 \
INTERMEDIATE_KEY_PKCS11_URI="pkcs11:type=private;object=Intermediate%20CA" \
INTERMEDIATE_KEY_PKCS11_MODULE=/usr/lib/opensc-pkcs11.so \
./pki-leaf-cert.sh example.com
```

**YubiKey with specific slot:**
```bash
INTERMEDIATE_KEY_LOCATION=pkcs11 \
INTERMEDIATE_KEY_PKCS11_URI="pkcs11:type=private;id=%01;object=Intermediate-CA;pin-value=123456" \
./pki-leaf-cert.sh example.com
```

**Using YubiKey for BOTH Intermediate CA certificate and key:**
```bash
INTERMEDIATE_CERT_LOCATION=pkcs11 \
INTERMEDIATE_CERT_PKCS11_URI="pkcs11:type=cert;object=Intermediate%20CA" \
INTERMEDIATE_KEY_LOCATION=pkcs11 \
INTERMEDIATE_KEY_PKCS11_URI="pkcs11:type=private;object=Intermediate%20CA" \
./pki-leaf-cert.sh example.com
```

### Output Files

```
leafs/example.com/
├── private/
│   └── leaf.key.pem           # Private key
├── certs/
│   ├── leaf.crt.pem           # Certificate (PEM)
│   ├── leaf.crt.der           # Certificate (DER)
│   └── leaf.pfx               # Certificate (PKCS#12)
├── bundle/
│   ├── leaf.chain.pem         # Certificate + Intermediate + Root
│   └── leaf.fullchain.pem     # Full chain with key
├── crl/
│   └── <hash>.crl             # CRL
└── ocsp/
    ├── leaf.ocsp.req          # OCSP request
    └── leaf.ocsp.resp         # OCSP response (if OCSP responder exists)
```

### Verification

After generating, the script automatically verifies:
```bash
openssl verify -CAfile pki/root/certs/ca.root.crt.pem \
    -untrusted pki/intermediate/certs/ca.chain.crt.pem \
    pki/leafs/example.com/certs/leaf.crt.pem
```

## Using Certificates

### Apache HTTP Server

```apache
SSLCertificateFile    /path/to/leafs/example.com/certs/leaf.crt.pem
SSLCertificateKeyFile /path/to/leafs/example.com/private/leaf.key.pem
SSLCertificateChainFile /path/to/leafs/example.com/bundle/leaf.chain.pem
```

### Nginx

```nginx
ssl_certificate     /path/to/leafs/example.com/bundle/leaf.chain.pem;
ssl_certificate_key /path/to/leafs/example.com/private/leaf.key.pem;
```

### Kubernetes (Kubernetes TLS Secret)

```bash
kubectl create secret tls example-com-tls \
    --cert=leafs/example.com/certs/leaf.crt.pem \
    --key=leafs/example.com/private/leaf.key.pem
```

### Java KeyStore

```bash
openssl pkcs12 -export \
    -in leafs/example.com/certs/leaf.crt.pem \
    -inkey leafs/example.com/private/leaf.key.pem \
    -out example.com.p12 \
    -name example.com

keytool -importkeystore \
    -srckeystore example.com.p12 \
    -srcstoretype PKCS12 \
    -destkeystore keystore.jks
```

### Docker/Containers

```bash
# Copy certificates into container
COPY leafs/example.com/private/leaf.key.pem /etc/ssl/private/leaf.key.pem
COPY leafs/example.com/certs/leaf.crt.pem /etc/ssl/certs/leaf.crt.pem
COPY leafs/example.com/bundle/leaf.chain.pem /etc/ssl/certs/leaf.chain.pem
```

## CRL and OCSP

### Check CRL

```bash
openssl crl -in pki/intermediate/crl/intermediate.crl.pem -inform PEM -noout -text
```

### Download and Check CRL

```bash
# Apache style
SSLCARevocationCheck chain
SSLCARevocationFile /path/to/intermediate.crl.pem

# Nginx style
ssl_crl /path/to/intermediate.crl.pem;
```

### OCSP Stapling (Server Side)

```bash
# Generate OCSP response (requires OCSP responder setup)
openssl ocsp \
    -index pki/intermediate/index.txt \
    -CA pki/intermediate/certs/ca.intermediate.crt.pem \
    -rkey pki/intermediate/private/ocsp.key.pem \
    -rsigner pki/intermediate/certs/ocsp.intermediate.crt.pem \
    -respout response.der \
    -respout text.der
```

### Check Certificate OCSP Status

```bash
openssl ocsp \
    -CAfile pki/root/certs/ca.root.crt.pem \
    -issuer pki/intermediate/certs/ca.intermediate.crt.pem \
    -cert pki/leafs/example.com/certs/leaf.crt.pem \
    -respout /tmp/ocsp.resp \
    -resquest /tmp/ocsp.req \
    -text
```

## Certificate Formats

### PEM (Privacy-Enhanced Mail)
Default format. Base64-encoded with headers.

```bash
# View PEM
cat leaf.crt.pem

# Convert to text
openssl x509 -in leaf.crt.pem -text -noout
```

### DER (Distinguished Encoding Rules)
Binary format, commonly used in Java.

```bash
# Convert PEM to DER
openssl x509 -in leaf.crt.pem -outform DER -out leaf.crt.der

# Convert DER to PEM
openssl x509 -in leaf.crt.der -inform DER -out leaf.crt.pem
```

### PKCS#12 / PFX
Contains both certificate and private key.

```bash
# Create PFX
openssl pkcs12 -export \
    -in leaf.crt.pem \
    -inkey leaf.key.pem \
    -out leaf.pfx

# Extract from PFX
openssl pkcs12 -in leaf.pfx -nodes -out leaf-combined.pem

# Extract certificate only
openssl pkcs12 -in leaf.pfx -nokeys -out leaf.crt.pem

# Extract key only
openssl pkcs12 -in leaf.pfx -nocerts -out leaf.key.pem
```

## Certificate Inspection

### View Certificate Details

```bash
openssl x509 -in leaf.crt.pem -noout -text
openssl x509 -in leaf.crt.pem -noout -subject -issuer
openssl x509 -in leaf.crt.pem -noout -dates
openssl x509 -in leaf.crt.pem -noout -serial
openssl x509 -in leaf.crt.pem -noout -fingerprint -sha256
```

### View SANs

```bash
openssl x509 -in leaf.crt.pem -noout -text | grep -A1 "Subject Alternative Name"
```

### Check Private Key

```bash
openssl rsa -in leaf.key.pem -check
openssl ec -in leaf.key.pem -check
```

### Check CSR

```bash
openssl req -in leaf.csr.pem -text -noout
```

## Troubleshooting

### Pre-requisites

```bash
brew install gnutls libp11 opensc openssl@3 p11-kit pkcs11-tools ykman yubico-piv-tool
```

### PKCS11 URIs

```bash
p11tool --provider /opt/homebrew/lib/libykcs11.dylib --list-certs --login
p11tool --provider /opt/homebrew/lib/libykcs11.dylib --list-keys --login
```


### "unable to get local issuer certificate"

The intermediate CA is not properly linked. Ensure:
1. Root CA is in the trust store
2. Intermediate CA is signed by the Root CA
3. Use the chain bundle for server certificates

### "certificate chain too long"

Your PKI has more than 2 tiers. Adjust verification commands.

### "self-signed certificate"

The intermediate CA must be signed by the Root CA, not self-signed. Run `pki-root-ca.sh` and `pki-intermediate-ca.sh` first.

### Key Permission Issues

```bash
chmod 400 /path/to/private/key.pem
chmod 755 /path/to/certs/
```

## Security Best Practices

1. **Protect Private Keys**: Keep permissions at 400 or 600
2. **Use Hardware Tokens**: For production, use HSM or YubiKey for CA keys
3. **Short Validity**: Use shorter validity periods for production certificates
4. **Monitor Expiration**: Set up alerts for certificate expiration
5. **Rotate CRLs**: Regularly update and distribute CRLs
6. **Backup Keys**: Securely backup CA keys offline

## Terraform TLS Provider Integration

You can use the generated certificates with Terraform's TLS provider for infrastructure provisioning.

### Generate Certificates with Terraform

Create a `terraform.tf` file:

```hcl
terraform {
  required_providers {
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
}

provider "tls" {}

variable "cert_common_name" {
  description = "Common name for the certificate"
  type        = string
  default     = "example.com"
}

variable "cert_san" {
  description = "Subject Alternative Names"
  type        = list(string)
  default     = ["example.com", "www.example.com"]
}

variable "validity_hours" {
  description = "Certificate validity in hours"
  type        = number
  default     = 8760 # 1 year
}

# Generate a private key
resource "tls_private_key" "leaf" {
  algorithm   = "ECDSA"
  ecdsa_curve = "P256"
}

# Generate a CSR
resource "tls_cert_request" "leaf" {
  private_key_pem = tls_private_key.leaf.private_key_pem

  subject {
    common_name = var.cert_common_name
    organization = "Organization"
    organizational_unit = "IT"
    country = "US"
    province = "State"
    locality = "City"
  }

  dns_names = var.cert_san
}

# Import the CA certificates
data "local_file" "intermediate_ca_cert" {
  filename = "${path.module}/pki/intermediate/certs/ca.intermediate.crt.pem"
}

data "local_file" "root_ca_cert" {
  filename = "${path.module}/pki/root/certs/ca.root.crt.pem"
}

# Note: Terraform TLS provider cannot sign with external CAs.
# Use one of these approaches:
```

### Option 1: Use Self-Signed Certificate (Simplest)

```hcl
resource "tls_self_signed_cert" "leaf" {
  private_key_pem = tls_private_key.leaf.private_key_pem

  subject {
    common_name         = var.cert_common_name
    organization       = "Organization"
    organizational_unit = "IT"
    country            = "US"
    province           = "State"
    locality           = "City"
  }

  dns_names = var.cert_san

  validity_period_hours = var.validity_hours
  early_renewal_hours   = 720 # Renew 30 days before expiry

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
    "client_auth",
  ]
}

# Save certificate to file
resource "local_file" "cert" {
  filename = "${path.module}/certs/${var.cert_common_name}.crt"
  content  = tls_self_signed_cert.leaf.cert_pem
}

resource "local_file" "key" {
  filename = "${path.module}/keys/${var.cert_common_name}.key"
  content  = tls_private_key.leaf.private_key_pem
}
```

### Option 2: Generate CSR and Sign Externally

```hcl
# Output the CSR for external signing
output "csr_pem" {
  value     = tls_cert_request.leaf.cert_request_pem
  sensitive = false
}

# Save CSR for signing with your CA
resource "local_file" "csr" {
  filename = "${path.module}/requests/${var.cert_common_name}.csr"
  content  = tls_cert_request.leaf.cert_request_pem
}
```

### Option 3: Import Existing Certificates

```hcl
data "tls_certificate" "leaf" {
  cert = file("${path.module}/pki/leafs/${var.cert_common_name}/certs/leaf.crt.pem")
}

data "tls_private_key" "leaf" {
  private_key_pem = file("${path.module}/pki/leafs/${var.cert_common_name}/private/leaf.key.pem")
}

# Use the certificate
resource "aws_acm_certificate" "main" {
  certificate_body = data.tls_certificate.leaf.cert_pem
  private_key     = data.tls_private_key.leaf.private_key_pem
}
```

### Option 4: Complete PKI with External Signing Script

```hcl
# Generate key and CSR with Terraform
resource "tls_private_key" "leaf" {
  algorithm   = "ECDSA"
  ecdsa_curve = "P256"
}

resource "tls_cert_request" "leaf" {
  private_key_pem = tls_private_key.leaf.private_key_pem

  subject {
    common_name = var.cert_common_name
    organization = "Organization"
    country = "US"
  }

  dns_names = var.cert_san
}

# Save CSR
resource "local_file" "csr" {
  filename = "${path.module}/requests/${var.cert_common_name}.csr"
  content  = tls_cert_request.leaf.cert_request_pem
}

resource "local_file" "key" {
  filename = "${path.module}/keys/${var.cert_common_name}.key"
  content  = tls_private_key.leaf.private_key_pem
}

# Create a null_resource to run the signing script
resource "null_resource" "sign_certificate" {
  triggers = {
    csr_changed = tls_cert_request.leaf.cert_request_pem
  }

  provisioner "local-exec" {
    command = <<-EOT
      cd ${path.module}
      # Sign the CSR with your Intermediate CA
      PKI_DIR=${path.module}/pki \
      ./scripts/pki-leaf-cert.sh ${var.cert_common_name}
    EOT
  }
}

# Import the signed certificate
data "local_file" "signed_cert" {
  filename = "${path.module}/pki/leafs/${var.cert_common_name}/certs/leaf.crt.pem"
  depends_on = [null_resource.sign_certificate]
}
```

### Example: AWS ACM Certificate Import

```hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

# Import existing CA chain
data "local_file" "intermediate_ca" {
  filename = "${path.module}/pki/intermediate/certs/ca.intermediate.crt.pem"
}

data "local_file" "root_ca" {
  filename = "${path.module}/pki/root/certs/ca.root.crt.pem"
}

# Import signed certificate
data "local_file" "certificate" {
  filename = "${path.module}/pki/leafs/example.com/certs/leaf.crt.pem"
}

data "local_file" "private_key" {
  filename = "${path.module}/pki/leafs/example.com/private/leaf.key.pem"
}

# Import certificate into AWS ACM
resource "aws_acm_certificate" "domain" {
  certificate_body = data.local_file.certificate.content
  private_key     = data.local_file.private_key.content
  certificate_chain = data.local_file.intermediate_ca.content

  tags = {
    Name = "example.com"
  }
}

# Create CloudFront distribution with HTTPS
resource "aws_cloudfront_distribution" "cdn" {
  origin {
    domain_name = "example.cloudfront.net"
    origin_id   = "custom-origin"
  }

  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"

  default_cache_behavior {
    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  viewer_certificate {
    acm_certificate_id = aws_acm_certificate.domain.id
    ssl_support_method  = "sni-only"
  }
}
```

### Example: Kubernetes Secret

```hcl
resource "local_file" "tls_cert" {
  filename = "${path.module}/tls.crt"
  content  = data.local_file.certificate.content
}

resource "local_file" "tls_key" {
  filename = "${path.module}/tls.key"
  content  = data.local_file.private_key.content
}

resource "kubernetes_secret" "tls" {
  metadata {
    name      = "example-com-tls"
    namespace = "default"
  }

  data = {
    "tls.crt" = local_file.tls_cert.content
    "tls.key" = local_file.tls_key.content
  }

  type = "kubernetes.io/tls"
}
```

### Example: Azure Key Vault Certificate

```hcl
resource "azurerm_key_vault_certificate" "main" {
  name         = "example-com"
  key_vault_id = azurerm_key_vault.main.id

  certificate {
    content = data.local_file.certificate.content
  }

  private_key {
    content = data.local_file.private_key.content
  }
}
```

## Refs

* https://github.com/drduh/YubiKey-Guide?tab=readme-ov-file#configure-yubikey
* https://yubikey.jms1.info/setup/load-yubikey.html
* https://dennis.silvrback.com/establish-multi-level-public-key-infrastructure-using-openssl
* https://pki-tutorial-ng.readthedocs.io/en/latest/simple/root-ca.conf.html
* https://github.com/CyberHashira/Learn_OpenSSL/blob/main/setup_two_tier_pki_using_openssl.md
* https://www.thecrosseroads.net/2022/06/creating-a-two-tier-ca-using-yubikeys/
* https://cryptobook.nakov.com/asymmetric-key-ciphers/elliptic-curve-cryptography-ecc
* https://twdev.blog/2023/12/homelab_ssl/

## License

MIT

