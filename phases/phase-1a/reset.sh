#!/usr/bin/env bash
set -euo pipefail

RUNTIME_DIR="${EKTISIS_RUNTIME_DIR:-$HOME/ektisis-runtime}"
PHASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMPOSE_FILE="$PHASE_DIR/compose.yml"
ENV_FILE="$RUNTIME_DIR/compose/phase-1a/.env"

remove_path() {
  local path="$1"

  if [ ! -e "$path" ]; then
    return 0
  fi

  if rm -rf "$path" 2>/dev/null; then
    return 0
  fi

  echo "Need sudo to remove container-owned data: $path"
  sudo rm -rf "$path"
}

if [ "${1:-}" != "--yes" ]; then
  echo "This will reset Phase 1A data and generate a new database password."
  echo
  echo "It removes:"
  echo "- $RUNTIME_DIR/data/postgres"
  echo "- $RUNTIME_DIR/data/gitea"
  echo "- $ENV_FILE"
  echo
  echo "Some files may belong to containers, so the reset may ask for sudo."
  echo
  echo "Use this only before the real Gitea setup, or when you intentionally want to start over."
  echo
  echo "Run:"
  echo
  echo "bash phases/phase-1a/reset.sh --yes"
  exit 1
fi

if [ -f "$ENV_FILE" ]; then
  docker compose --env-file "$ENV_FILE" -f "$COMPOSE_FILE" -p ektisis-phase-1a down || true
else
  docker compose -f "$COMPOSE_FILE" -p ektisis-phase-1a down || true
fi

remove_path "$RUNTIME_DIR/data/postgres"
remove_path "$RUNTIME_DIR/data/gitea"
remove_path "$RUNTIME_DIR/data/gitea-config"
rm -f "$ENV_FILE"

echo "Phase 1A was reset."
echo
echo "Run again:"
echo
echo "bash phases/phase-1a/bootstrap.sh"
echo "bash phases/phase-1a/validate.sh"
