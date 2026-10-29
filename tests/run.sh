#!/usr/bin/env bash
set -Eeuo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."

for f in install.sh scripts/*.sh; do
  bash -n "$f"
  printf 'syntax OK: %s\n' "$f"
done

[ -f docker-compose.yml ]
[ -f .env.example ]
[ -f deploy/caddy/Caddyfile ]
grep -q 'nousresearch/hermes-agent' docker-compose.yml
grep -q 'HERMES_DASHBOARD=1' .env.example
grep -q 'restart: unless-stopped' docker-compose.yml

if command -v docker >/dev/null 2>&1; then
  created_env=0
  if [ ! -f .env ]; then
    cp .env.example .env
    created_env=1
  fi
  trap '[ "$created_env" -eq 1 ] && rm -f .env' EXIT
  docker compose config --quiet
  printf 'compose config OK\n'
else
  printf 'SKIP: docker is not installed; compose config not checked\n'
fi

printf 'Static checks passed.\n'
