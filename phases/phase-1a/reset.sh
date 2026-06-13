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

  if sudo rm -rf "$path" 2>/dev/null; then
    return 0
  fi

  echo "Could not remove Phase 1A data: $path"
  echo
  echo "Try running the reset again, or check file permissions."
  exit 1
}

if [ "${1:-}" != "--yes" ]; then
  echo "This will reset Phase 1A and start it from zero."
  echo
  echo "It removes the Phase 1A database, Gitea files, and generated environment file."
  echo
  echo "Use this only before real repositories or users exist, or when you intentionally want to start over."
  echo
  echo "Run:"
  echo
  echo "bash phases/phase-1a/reset.sh --yes"
  exit 1
fi

echo "Resetting Phase 1A services..."

if [ -f "$ENV_FILE" ]; then
  docker compose --env-file "$ENV_FILE" -f "$COMPOSE_FILE" -p ektisis-phase-1a down >/dev/null 2>&1 || true
else
  docker compose -f "$COMPOSE_FILE" -p ektisis-phase-1a down >/dev/null 2>&1 || true
fi

echo "Removing Phase 1A data..."

remove_path "$RUNTIME_DIR/data/postgres"
remove_path "$RUNTIME_DIR/data/gitea"
remove_path "$RUNTIME_DIR/data/gitea-config"
rm -f "$ENV_FILE"

echo
echo "Phase 1A was reset."
echo
echo "Run again:"
echo
echo "bash phases/phase-1a/bootstrap.sh"
echo "bash phases/phase-1a/validate.sh"
