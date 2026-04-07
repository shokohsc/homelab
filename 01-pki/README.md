# PKI Infrastructure
- Offline root CA and intermediate CA(s) for certificate management.
- Keys and certificates are stored on a YubiKey 5C NFC.
- Keys are also backed up to a USB drive and encrypted with a GPG key.

## Pre-requisites
- brew install gnutls libp11 opensc openssl@3 p11-kit pkcs11-tools ykman yubico-piv-tool
- find pkcs11 uris and update them as needed in 03-server-yubikey-issue.sh

    $ p11tool --provider /opt/homebrew/lib/libykcs11.dylib --list-keys --login

    $ p11tool --provider /opt/homebrew/lib/libykcs11.dylib --list-certs --login

## Scripts
- 01-pki-init.sh
- 02-pki-import.sh
- 03-server-yubikey-issue.sh

These scripts create a root CA, an intermediate CA, and a server certificate.

The Root CA will be stored on a YubiKey 5C NFC and a USB drive.

The intermediate CA will be stored on a YubiKey 5C NFC and a USB drive.

The intermediate CA will be add to devices trusted store and cert-manager in the Kubernetes cluster later.

The server certificates issued by the intermediate CA will be used on devices exposing tls endpoints.

## Refs
https://github.com/drduh/YubiKey-Guide?tab=readme-ov-file#configure-yubikey

https://yubikey.jms1.info/setup/load-yubikey.html


https://dennis.silvrback.com/establish-multi-level-public-key-infrastructure-using-openssl

https://pki-tutorial-ng.readthedocs.io/en/latest/simple/root-ca.conf.html

https://github.com/CyberHashira/Learn_OpenSSL/blob/main/setup_two_tier_pki_using_openssl.md

https://www.thecrosseroads.net/2022/06/creating-a-two-tier-ca-using-yubikeys/

https://cryptobook.nakov.com/asymmetric-key-ciphers/elliptic-curve-cryptography-ecc


https://twdev.blog/2023/12/homelab_ssl/
