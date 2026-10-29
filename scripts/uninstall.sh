#!/usr/bin/env bash
set -Eeuo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."
PURGE=0
[ "${1:-}" = "--purge" ] && PURGE=1

docker compose --profile proxy down

if [ "$PURGE" -eq 1 ]; then
  printf 'Deleting %s and all Hermes data. Type DELETE to continue: ' "$PWD"
  read -r answer
  [ "$answer" = "DELETE" ] || { echo "Cancelled"; exit 1; }
  cd /
  rm -rf "$OLDPWD"
  printf 'Removed.\n'
else
  printf 'Containers stopped. Data kept in ./data. Use --purge to delete everything.\n'
fi
