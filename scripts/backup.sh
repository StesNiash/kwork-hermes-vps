#!/usr/bin/env bash
set -Eeuo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."
STACK_DIR="$PWD"
BACKUP_DIR="${1:-$STACK_DIR/backups}"
mkdir -p "$BACKUP_DIR"
chmod 700 "$BACKUP_DIR"

stamp="$(date -u +%Y%m%d-%H%M%S)"
archive="$BACKUP_DIR/hermes-data-$stamp.tar.gz"

restart() {
  docker compose start hermes >/dev/null 2>&1 || true
}
trap restart EXIT

docker compose stop hermes
tar -C "$STACK_DIR" -czf "$archive" data
chmod 600 "$archive"
restart
trap - EXIT

printf 'Backup: %s\n' "$archive"
