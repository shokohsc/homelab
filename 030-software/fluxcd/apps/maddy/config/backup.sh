#!/usr/bin/env sh

set -euo pipefail

log () {
  echo "$(date "+%Y-%m-%d %H:%M:%S") [${2:-INFO}]: $1"
}

apk add --no-cache git
update-ca-certificates
cat /usr/local/share/ca-certificates/maddy.${domain}.crt >> /etc/ssl/ca-certificates.crt

git clone https://github.com/mlnoga/go-imap-backup.git
cd go-imap-backup/
go build

rm -rf /backup/postmaster || true
log "Backup $POSTMASTER_ACCOUNT"
mkdir -p /backup/postmaster || true
./go-imap-backup -s "$IMAP_SERVER" -u "$POSTMASTER_ACCOUNT" -P "$POSTMASTER_PASSWORD" -l /backup/postmaster backup

rm -rf /backup/catchall || true
log "Backup $CATCHALL_ACCOUNT"
mkdir -p /backup/catchall || true
./go-imap-backup -s "$IMAP_SERVER" -u "$CATCHALL_ACCOUNT" -P "$CATCHALL_PASSWORD" -l /backup/catchall backup

chmod 644 -R /backup/catchall
chmod 644 -R /backup/postmaster

chmod 755 /backup/catchall
chmod 755 /backup/postmaster

log "Exiting..."
exit 0