#!/usr/bin/env bash
set -Eeuo pipefail

STACK_DIR="${HERMES_STACK_DIR:-/opt/hermes-stack}"
NON_INTERACTIVE=0
WITH_DOCKER=0
SKIP_PULL=0

usage() {
  cat <<'EOF'
Usage: sudo ./install.sh [options]

Options:
  --dir PATH          install directory (default: /opt/hermes-stack)
  --non-interactive   do not prompt; read values from env or .env
  --with-docker       install Docker Engine + compose plugin if missing
  --skip-pull         do not pull the image before start
  -h, --help          show this help
EOF
}

while [ $# -gt 0 ]; do
  case "$1" in
    --dir) STACK_DIR="${2:?--dir needs a path}"; shift 2 ;;
    --non-interactive) NON_INTERACTIVE=1; shift ;;
    --with-docker) WITH_DOCKER=1; shift ;;
    --skip-pull) SKIP_PULL=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "unknown option: $1" >&2; usage; exit 2 ;;
  esac
done

if [ "$(id -u)" -ne 0 ]; then
  echo "Run as root: sudo ./install.sh" >&2
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

log() { printf '\n==> %s\n' "$*"; }
warn() { printf 'WARN: %s\n' "$*" >&2; }
die() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }

if [ -r /etc/os-release ]; then
  # shellcheck disable=SC1091
  . /etc/os-release
  case "${ID:-}:${VERSION_ID:-}" in
    ubuntu:22.04|ubuntu:24.04|debian:12) ;;
    *) warn "tested on Ubuntu 22.04/24.04 and Debian 12; current: ${PRETTY_NAME:-unknown}" ;;
  esac
fi

need_cmd() { command -v "$1" >/dev/null 2>&1; }

log "Installing base packages"
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get install -y -qq curl ca-certificates git tar openssl >/dev/null

if ! need_cmd docker; then
  if [ "$WITH_DOCKER" -eq 1 ]; then
    log "Installing Docker Engine"
    curl -fsSL https://get.docker.com | sh
    systemctl enable --now docker
  else
    die "docker is missing. Re-run with --with-docker or install Docker manually."
  fi
fi

if ! docker compose version >/dev/null 2>&1; then
  log "Installing docker compose plugin"
  apt-get install -y -qq docker-compose-plugin >/dev/null || die "cannot install docker-compose-plugin"
fi

log "Preparing $STACK_DIR"
install -d -m 0755 "$STACK_DIR"
if [ "$SCRIPT_DIR" != "$STACK_DIR" ]; then
  cp -a "$SCRIPT_DIR/docker-compose.yml" "$SCRIPT_DIR/.env.example" "$SCRIPT_DIR/install.sh" "$STACK_DIR/"
  cp -a "$SCRIPT_DIR/scripts" "$SCRIPT_DIR/deploy" "$STACK_DIR/"
fi
cd "$STACK_DIR"
install -d -m 0700 data

if [ ! -f .env ]; then
  cp .env.example .env
  chmod 600 .env
fi

get_env() {
  grep -E "^$1=" .env 2>/dev/null | head -n1 | cut -d= -f2- || true
}

set_env() {
  local key="$1" value="$2" tmp
  tmp="$(mktemp)"
  awk -v k="$key" -v v="$value" '
    BEGIN { done = 0 }
    index($0, k "=") == 1 { print k "=" v; done = 1; next }
    { print }
    END { if (!done) print k "=" v }
  ' .env > "$tmp"
  mv "$tmp" .env
  chmod 600 .env
}

telegram_token="${TELEGRAM_BOT_TOKEN:-$(get_env TELEGRAM_BOT_TOKEN)}"
openrouter_key="${OPENROUTER_API_KEY:-$(get_env OPENROUTER_API_KEY)}"
dashboard_password="$(get_env HERMES_DASHBOARD_BASIC_AUTH_PASSWORD)"

if [ "$NON_INTERACTIVE" -eq 0 ]; then
  if [ -z "$telegram_token" ]; then
    read -r -p "Telegram bot token (from @BotFather): " telegram_token
  fi
  if [ -z "$openrouter_key" ]; then
    read -r -p "OpenRouter API key (optional, Enter to configure later): " openrouter_key
  fi
fi

[ -n "$telegram_token" ] || die "TELEGRAM_BOT_TOKEN is required"
if ! printf '%s' "$telegram_token" | grep -Eq '^[0-9]{6,}:[A-Za-z0-9_-]{20,}$'; then
  die "Telegram token does not look valid (expected 123456:ABC...)"
fi

if [ -n "$openrouter_key" ]; then
  set_env OPENROUTER_API_KEY "$openrouter_key"
fi
set_env TELEGRAM_BOT_TOKEN "$telegram_token"

if [ -z "$dashboard_password" ]; then
  dashboard_password="$(openssl rand -base64 18 | tr -dc 'A-Za-z0-9' | head -c 20)"
  set_env HERMES_DASHBOARD_BASIC_AUTH_PASSWORD "$dashboard_password"
fi
if [ -z "$(get_env HERMES_DASHBOARD_BASIC_AUTH_SECRET)" ]; then
  set_env HERMES_DASHBOARD_BASIC_AUTH_SECRET "$(openssl rand -hex 32)"
fi
if [ -z "$(get_env API_SERVER_KEY)" ]; then
  set_env API_SERVER_KEY "$(openssl rand -hex 32)"
fi
if [ -z "$(get_env HERMES_CPUS)" ]; then
  set_env HERMES_CPUS "$(nproc)"
fi
if [ -z "$(get_env HERMES_MEM_LIMIT)" ]; then
  set_env HERMES_MEM_LIMIT "4g"
fi

log "Validating compose file"
docker compose config --quiet

if [ "$SKIP_PULL" -eq 0 ]; then
  log "Pulling Hermes image"
  docker compose pull hermes
fi

log "Starting Hermes gateway"
docker compose up -d hermes

log "Waiting for healthcheck (up to 3 minutes)"
status="unknown"
for _ in $(seq 1 36); do
  status="$(docker inspect -f '{{if .State.Health}}{{.State.Health.Status}}{{else}}{{.State.Status}}{{end}}' hermes 2>/dev/null || true)"
  [ "$status" = "healthy" ] && break
  sleep 5
done

if [ "$status" != "healthy" ]; then
  docker compose logs --tail=80 hermes || true
  die "Hermes did not become healthy (status: $status). Fix the logs above and re-run."
fi

log "Running smoke checks"
./scripts/smoke.sh

cat <<EOF

Hermes is running.

  dashboard (localhost only): http://127.0.0.1:9119
  dashboard user:             $(get_env HERMES_DASHBOARD_BASIC_AUTH_USERNAME)
  dashboard password:         $dashboard_password

  SSH tunnel from your laptop:
    ssh -L 9119:127.0.0.1:9119 root@<your-vps-ip>

  Telegram: message your bot, then approve pairing if asked:
    docker compose exec -T hermes hermes pairing list
    docker compose exec -T hermes hermes pairing approve <id>

  Logs:     ./scripts/logs.sh
  Backup:   ./scripts/backup.sh
  Update:   ./scripts/update.sh
  Stop:     docker compose down

Keep .env private. It contains the bot token and API keys.
EOF
