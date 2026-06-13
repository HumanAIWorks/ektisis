#!/usr/bin/env bash
set -euo pipefail

RUNTIME_DIR="${EKTISIS_RUNTIME_DIR:-$HOME/ektisis-runtime}"
PHASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMPOSE_FILE="$PHASE_DIR/compose.yml"
ENV_FILE="$RUNTIME_DIR/compose/phase-1a/.env"

if [ "${1:-}" != "--yes" ]; then
  echo "This will reset Phase 1A data and generate a new database password."
  echo
  echo "It removes:"
  echo "- $RUNTIME_DIR/data/postgres"
  echo "- $RUNTIME_DIR/data/gitea"
  echo "- $ENV_FILE"
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

rm -rf "$RUNTIME_DIR/data/postgres"
rm -rf "$RUNTIME_DIR/data/gitea"
rm -rf "$RUNTIME_DIR/data/gitea-config"
rm -f "$ENV_FILE"

echo "Phase 1A was reset."
echo
echo "Run again:"
echo
echo "bash phases/phase-1a/bootstrap.sh"
echo "bash phases/phase-1a/validate.sh"
