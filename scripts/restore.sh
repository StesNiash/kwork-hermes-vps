#!/usr/bin/env bash
set -Eeuo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."
STACK_DIR="$PWD"
archive="${1:-}"
[ -n "$archive" ] || { echo "Usage: ./scripts/restore.sh backups/hermes-data-YYYYMMDD-HHMMSS.tar.gz" >&2; exit 2; }
[ -f "$archive" ] || { echo "Archive not found: $archive" >&2; exit 2; }

tar -tzf "$archive" >/dev/null || { echo "Not a valid tar.gz: $archive" >&2; exit 2; }

stamp="$(date -u +%Y%m%d-%H%M%S)"
docker compose stop hermes || true
if [ -d data ]; then
  mv data "data.pre-restore-$stamp"
fi
tar -C "$STACK_DIR" -xzf "$archive"
chmod 700 data
docker compose up -d hermes
printf 'Restored %s\nPrevious data kept in data.pre-restore-%s\n' "$archive" "$stamp"
