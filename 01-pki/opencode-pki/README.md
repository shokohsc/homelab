# PKI and TLS Certificate Generation Scripts

Two bash scripts for creating a two-tier PKI infrastructure and generating TLS certificates using only OpenSSL.

## Scripts

- `pki-setup.sh` - Creates Root CA and Intermediate CA
- `tls-cert.sh` - Generates TLS certificates from the Intermediate CA

## Directory Structure

```
pki/
├── pki-setup.sh              # PKI setup script
├── tls-cert.sh               # TLS certificate generation script
├── root/
│   ├── private/              # Root CA private key (chmod 700)
│   ├── certs/                # Root CA certificate
│   ├── crl/                  # Root CA CRL
│   └── newcerts/             # New certificates directory
├── intermediate/
│   ├── private/              # Intermediate CA private key
│   ├── certs/                # Intermediate CA certificate + chain
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

### 1. Setup PKI (Root and Intermediate CA)

```bash
cd /workspace/pki
./pki-setup.sh
```

### 2. Generate TLS Certificate

```bash
./tls-cert.sh example.com
```

## pki-setup.sh Options

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `PKI_DIR` | Working directory | `./pki` |
| `ROOT_CN` | Root CA Common Name | `My Root CA` |
| `ROOT_VALIDITY_DAYS` | Root certificate validity | `3650` (10 years) |
| `ROOT_KEY_ALG` | Root key algorithm (`rsa` or `ec`) | `ec` |
| `ROOT_KEY_SIZE` | Root key size (`prime256v1`, `secp384r1`, `2048`, `4096`) | `prime256v1` |
| `INTERMEDIATE_CN` | Intermediate CA Common Name | `My Intermediate CA` |
| `INTERMEDIATE_VALIDITY_DAYS` | Intermediate validity | `1825` (5 years) |
| `INTERMEDIATE_KEY_ALG` | Intermediate key algorithm | `ec` |
| `INTERMEDIATE_KEY_SIZE` | Intermediate key size | `prime256v1` |
| `INTERMEDIATE_KEY_LOCATION` | Key location (`file` or `pkcs11`) | `file` |
| `INTERMEDIATE_KEY_PATH` | Path to intermediate key (file mode) | auto-generated |
| `INTERMEDIATE_PKCS11_URI` | PKCS#11 URI (pkcs11 mode) | - |
| `COUNTRY` | Country code | `US` |
| `STATE` | State/Province | `State` |
| `LOCALITY` | City/Locality | `City` |
| `ORGANIZATION` | Organization name | `Organization` |
| `ORGANIZATIONAL_UNIT` | Organizational Unit | `IT` |
| `EMAIL` | Email address | `ca@example.com` |
| `CREATE_CRL` | Create CRLs (`true`/`false`) | `true` |
| `CREATE_OCSP_RESPONDER` | Create OCSP responder certs | `false` |
| `AUTO_OVERWRITE` | Auto overwrite files (`true`/`false`) | `false` |

### Examples

**Default setup:**
```bash
./pki-setup.sh
```

**Custom organization:**
```bash
ROOT_CN="Acme Corp Root CA" \
INTERMEDIATE_CN="Acme Corp Intermediate CA" \
ORGANIZATION="Acme Corporation" \
./pki-setup.sh
```

**RSA keys:**
```bash
ROOT_KEY_ALG=rsa ROOT_KEY_SIZE=4096 \
INTERMEDIATE_KEY_ALG=rsa INTERMEDIATE_KEY_SIZE=2048 \
./pki-setup.sh
```

**Using YubiKey (PKCS#11):**
```bash
INTERMEDIATE_KEY_LOCATION=pkcs11 \
INTERMEDIATE_PKCS11_URI="pkcs11:type=private;object=Intermediate%20CA;pin-value=your_pin" \
./pki-setup.sh
```

**Shorter validity for testing:**
```bash
ROOT_VALIDITY_DAYS=365 INTERMEDIATE_VALIDITY_DAYS=180 \
./pki-setup.sh
```

**Auto overwrite without prompting:**
```bash
AUTO_OVERWRITE=true ./pki-setup.sh
```

### Output Files

- `root/private/ca.root.key.pem` - Root CA private key
- `root/certs/ca.root.crt.pem` - Root CA certificate
- `root/crl/root.crl.pem` - Root CA CRL
- `intermediate/private/ca.intermediate.key.pem` - Intermediate CA key
- `intermediate/certs/ca.intermediate.crt.pem` - Intermediate CA certificate
- `intermediate/certs/ca.chain.crt.pem` - CA chain bundle (Intermediate + Root)
- `intermediate/crl/intermediate.crl.pem` - Intermediate CA CRL

### Verification

After running, the script automatically verifies:
```bash
openssl verify -CAfile pki/root/certs/ca.root.crt.pem pki/intermediate/certs/ca.intermediate.crt.pem
```

## tls-cert.sh Options

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `PKI_DIR` | PKI directory | `./pki` |
| `OUTPUT_DIR` | Output directory for certificates | `${PKI_DIR}/leafs` |
| `INTERMEDIATE_CERT_FILE` | Intermediate CA certificate path | auto |
| `INTERMEDIATE_KEY_FILE` | Intermediate CA key path | auto |
| `ROOT_CERT_FILE` | Root CA certificate path | auto |
| `CHAIN_BUNDLE_FILE` | CA chain bundle path | auto |
| `CERT_CN` | Certificate Common Name | `example.com` |
| `CERT_SAN` | Subject Alternate Names (comma-separated) | same as CERT_CN |
| `CERT_VALIDITY_DAYS` | Certificate validity | `365` |
| `CERT_KEY_ALG` | Key algorithm (`rsa` or `ec`) | `ec` |
| `CERT_KEY_SIZE` | Key size | `prime256v1` |
| `OUTPUT_FORMATS` | Output formats (crt,pem,der,pfx) | `crt,pem,der,pfx` |
| `CREATE_CRL` | Create CRL | `true` |
| `CREATE_OCSP_REQUEST` | Create OCSP request | `true` |
| `COUNTRY`, `STATE`, etc. | Subject components | same as pki-setup |
| `AUTO_OVERWRITE` | Auto overwrite | `false` |

### Examples

**Basic certificate:**
```bash
./tls-cert.sh example.com
```

**With SANs:**
```bash
CERT_SAN="example.com,www.example.com,api.example.com" \
./tls-cert.sh example.com
```

**IP addresses in SANs:**
```bash
CERT_SAN="example.com,192.168.1.1,10.0.0.1" \
./tls-cert.sh example.com
```

**Wildcard certificate:**
```bash
CERT_CN="*.example.com" \
CERT_SAN="example.com,*.example.com" \
./tls-cert.sh wildcard
```

**RSA key:**
```bash
CERT_KEY_ALG=rsa CERT_KEY_SIZE=4096 \
./tls-cert.sh example.com
```

**Custom output directory:**
```bash
OUTPUT_DIR="/etc/ssl/private" \
./tls-cert.sh example.com
```

**Only PEM and PFX output:**
```bash
OUTPUT_FORMATS="pem,pfx" \
./tls-cert.sh example.com
```

**Multiple certificates:**
```bash
./tls-cert.sh example.com
CERT_CN="api.example.com" CERT_SAN="api.example.com" ./tls-cert.sh api
CERT_CN="internal.local" CERT_SAN="internal.local,192.168.1.10" ./tls-cert.sh internal
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

### "unable to get local issuer certificate"

The intermediate CA is not properly linked. Ensure:
1. Root CA is in the trust store
2. Intermediate CA is signed by the Root CA
3. Use the chain bundle for server certificates

### "certificate chain too long"

Your PKI has more than 2 tiers. Adjust verification commands.

### "self-signed certificate"

The intermediate CA must be signed by the Root CA, not self-signed. Run `pki-setup.sh` first.

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

## License

MIT
