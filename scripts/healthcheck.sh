#!/usr/bin/env bash
set -Eeuo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."
status="$(docker inspect -f '{{if .State.Health}}{{.State.Health.Status}}{{else}}{{.State.Status}}{{end}}' hermes 2>/dev/null || echo missing)"
printf 'container: %s\n' "$status"
[ "$status" = "healthy" ] || exit 1
printf 'dashboard: http://127.0.0.1:9119 (localhost only)\n'
printf 'gateway:   http://127.0.0.1:8642/health\n'
