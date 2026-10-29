#!/usr/bin/env bash
set -Eeuo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."

docker compose pull hermes
docker compose up -d hermes

for _ in $(seq 1 36); do
  status="$(docker inspect -f '{{if .State.Health}}{{.State.Health.Status}}{{else}}{{.State.Status}}{{end}}' hermes 2>/dev/null || true)"
  [ "$status" = "healthy" ] && break
  sleep 5
done

[ "$status" = "healthy" ] || { docker compose logs --tail=80 hermes; exit 1; }
./scripts/smoke.sh
