#!/usr/bin/env bash
set -Eeuo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."

fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }

[ -f .env ] || fail ".env is missing"
[ -f docker-compose.yml ] || fail "docker-compose.yml is missing"

get_env() {
  grep -E "^$1=" .env 2>/dev/null | head -n1 | cut -d= -f2- || true
}

for key in TELEGRAM_BOT_TOKEN HERMES_DASHBOARD_BASIC_AUTH_PASSWORD API_SERVER_KEY; do
  [ -n "$(get_env "$key")" ] || fail "$key is empty in .env"
done

telegram_token="$(get_env TELEGRAM_BOT_TOKEN)"
printf '%s' "$telegram_token" | grep -Eq '^[0-9]{6,}:[A-Za-z0-9_-]{20,}$' \
  || fail "TELEGRAM_BOT_TOKEN has an unexpected format"

docker compose config --quiet || fail "docker compose config failed"

docker compose ps --status running --services | grep -qx hermes \
  || fail "hermes container is not running"

status="$(docker inspect -f '{{if .State.Health}}{{.State.Health.Status}}{{else}}{{.State.Status}}{{end}}' hermes 2>/dev/null || true)"
[ "$status" = "healthy" ] || fail "hermes health is '$status', expected 'healthy'"

api_enabled="$(get_env API_SERVER_ENABLED)"
api_key="$(get_env API_SERVER_KEY)"
if [ "$api_enabled" = "true" ] || [ "$api_enabled" = "1" ]; then
  curl -fsS --max-time 5 -H "Authorization: Bearer $api_key" http://127.0.0.1:8642/health >/dev/null \
    || fail "API server health endpoint did not answer on 127.0.0.1:8642"
fi

if docker compose logs --tail=200 hermes 2>/dev/null | grep -q 'Traceback (most recent call last)'; then
  fail "recent gateway log contains a Python traceback"
fi

printf 'OK: Hermes gateway is healthy, API and Telegram config look valid.\n'
