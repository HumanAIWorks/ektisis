#!/usr/bin/env bash
set -euo pipefail

RUNTIME_DIR="${EKTISIS_RUNTIME_DIR:-$HOME/ektisis-runtime}"
PHASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMPOSE_FILE="$PHASE_DIR/compose.yml"
ENV_FILE="$RUNTIME_DIR/compose/phase-1a/.env"

FAIL=0
PASS=0

ok() { echo "OK: $1"; PASS=$((PASS+1)); }
fail() { echo "FAIL: $1"; FAIL=$((FAIL+1)); }

load_env_value() {
  local key="$1"
  if [ -f "$ENV_FILE" ]; then
    awk -F= -v k="$key" '$1 == k {print substr($0, length(k) + 2); exit}' "$ENV_FILE"
  fi
}

echo "== Ektisis Phase 1A Validation =="
echo "Runtime directory: $RUNTIME_DIR"

[ -f "$ENV_FILE" ] && ok "environment file exists" || fail "missing environment file: $ENV_FILE"
[ -f "$COMPOSE_FILE" ] && ok "compose file exists" || fail "missing compose file: $COMPOSE_FILE"

docker ps >/dev/null 2>&1 && ok "Docker command works without sudo" || fail "Docker command does not work without sudo"
docker compose version >/dev/null 2>&1 && ok "Docker Compose works" || fail "Docker Compose not available"

if docker compose --env-file "$ENV_FILE" -f "$COMPOSE_FILE" -p ektisis-phase-1a ps >/dev/null 2>&1; then
  ok "Compose project can be inspected"
else
  fail "Compose project cannot be inspected"
fi

POSTGRES_RUNNING="$(docker inspect -f '{{.State.Running}}' ektisis-postgres 2>/dev/null || echo false)"
GITEA_RUNNING="$(docker inspect -f '{{.State.Running}}' ektisis-gitea 2>/dev/null || echo false)"

[ "$POSTGRES_RUNNING" = "true" ] && ok "PostgreSQL container is running" || fail "PostgreSQL container is not running"
[ "$GITEA_RUNNING" = "true" ] && ok "Gitea container is running" || fail "Gitea container is not running"

POSTGRES_HEALTH="$(docker inspect -f '{{if .State.Health}}{{.State.Health.Status}}{{else}}none{{end}}' ektisis-postgres 2>/dev/null || echo unknown)"
[ "$POSTGRES_HEALTH" = "healthy" ] && ok "PostgreSQL is healthy" || fail "PostgreSQL is not healthy: $POSTGRES_HEALTH"

HTTP_PORT="$(load_env_value GITEA_HTTP_PORT)"
if [ -z "$HTTP_PORT" ]; then
  HTTP_PORT="3000"
fi

if curl -fsS --max-time 5 "http://127.0.0.1:$HTTP_PORT/" >/dev/null 2>&1; then
  ok "Gitea HTTP responds locally on port $HTTP_PORT"
else
  fail "Gitea HTTP does not respond locally on port $HTTP_PORT"
fi

[ -d "$RUNTIME_DIR/data/postgres" ] && ok "PostgreSQL data directory exists" || fail "missing PostgreSQL data directory"
[ -d "$RUNTIME_DIR/data/gitea" ] && ok "Gitea data directory exists" || fail "missing Gitea data directory"
[ -d "$RUNTIME_DIR/data/gitea/gitea" ] && ok "Gitea work directory exists" || fail "missing Gitea work directory"

echo
echo "PASS: $PASS"
echo "FAIL: $FAIL"

if [ "$FAIL" -eq 0 ]; then
  DOMAIN="$(load_env_value GITEA_DOMAIN)"
  ROOT_URL="$(load_env_value GITEA_ROOT_URL)"
  echo
  echo "Phase 1A validated. Gitea + PostgreSQL are running."
  echo
  echo "Open Gitea:"
  echo
  if [ -n "$ROOT_URL" ]; then
    echo "$ROOT_URL"
  else
    echo "http://${DOMAIN:-localhost}:$HTTP_PORT/"
  fi
else
  echo
  echo "Phase 1A validation failed. Inspect logs:"
  echo
  echo "docker compose --env-file $ENV_FILE -f $COMPOSE_FILE -p ektisis-phase-1a logs --tail=100"
fi

[ "$FAIL" -eq 0 ]
