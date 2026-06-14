#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
RUNTIME_DIR="${EKTISIS_RUNTIME_DIR:-$HOME/ektisis-runtime}"
ENV_FILE="$RUNTIME_DIR/compose/phase-1/.env"
COMPOSE_FILE="$ROOT_DIR/phases/phase-1/compose.yml"
COMPOSE_PROJECT="ektisis-phase-1a"
MODE="containers"
YES="false"

cd "$ROOT_DIR"

usage() {
  cat <<'EOF_USAGE'
Usage:
  bash phases/phase-1/reset.sh [--containers|--runtime|--clean] [--yes]

Modes:
  --containers   Stop and recreate containers only. Keeps all runtime data and .env. Default.
  --runtime      Stop containers and remove generated runtime config. Keeps service data volumes.
  --clean        Stop containers and remove generated runtime config and Phase 1 service data.

Examples:
  bash phases/phase-1/reset.sh --containers
  bash phases/phase-1/reset.sh --runtime --yes
  bash phases/phase-1/reset.sh --clean --yes
EOF_USAGE
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --containers)
      MODE="containers"
      ;;
    --runtime)
      MODE="runtime"
      ;;
    --clean)
      MODE="clean"
      ;;
    --yes|-y)
      YES="true"
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1"
      usage
      exit 1
      ;;
  esac
  shift
done

confirm() {
  local message="$1"

  if [ "$YES" = "true" ]; then
    return 0
  fi

  echo "$message"
  printf 'Type yes to continue: '
  read -r answer
  [ "$answer" = "yes" ]
}

compose_down() {
  if [ -f "$ENV_FILE" ]; then
    docker compose \
      --env-file "$ENV_FILE" \
      -f "$COMPOSE_FILE" \
      -p "$COMPOSE_PROJECT" \
      down --remove-orphans || true
  else
    docker compose \
      -f "$COMPOSE_FILE" \
      -p "$COMPOSE_PROJECT" \
      down --remove-orphans || true
  fi
}

remove_path() {
  local path="$1"
  if [ ! -e "$path" ]; then
    return 0
  fi

  if rm -rf "$path" 2>/dev/null; then
    return 0
  fi

  sudo rm -rf "$path"
}

echo "== Ektisis Phase 1 Reset =="
echo "Mode: $MODE"
echo

case "$MODE" in
  containers)
    echo "This will recreate containers using the current .env and keep all data."
    compose_down
    if [ -f "$ENV_FILE" ]; then
      docker compose \
        --env-file "$ENV_FILE" \
        -f "$COMPOSE_FILE" \
        -p "$COMPOSE_PROJECT" \
        up -d --force-recreate
      bash phases/phase-1/reconcile.sh
    else
      echo "Runtime .env does not exist yet. Run: bash phases/phase-1/run.sh"
    fi
    ;;

  runtime)
    if ! confirm "This will remove generated Phase 1 runtime config, including .env, but keep service data."; then
      echo "Canceled."
      exit 1
    fi
    compose_down
    remove_path "$RUNTIME_DIR/compose/phase-1"
    echo "Runtime config removed. Service data was preserved."
    echo "Run again: bash phases/phase-1/run.sh"
    ;;

  clean)
    if ! confirm "This will remove Phase 1 containers, generated config, and service data. This is a clean reinstall."; then
      echo "Canceled."
      exit 1
    fi
    compose_down
    remove_path "$RUNTIME_DIR/compose/phase-1"
    remove_path "$RUNTIME_DIR/data/postgres"
    remove_path "$RUNTIME_DIR/data/gitea"
    remove_path "$RUNTIME_DIR/data/freellmapi"
    remove_path "$RUNTIME_DIR/data/redis"
    remove_path "$RUNTIME_DIR/data/openhands"
    echo "Phase 1 runtime config and service data removed."
    echo "Run again: bash phases/phase-1/run.sh"
    ;;
esac

echo
 echo "Phase 1 reset completed."
