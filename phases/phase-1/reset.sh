#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
RUNTIME_DIR="${EKTISIS_RUNTIME_DIR:-$HOME/ektisis-runtime}"
ENV_FILE="$RUNTIME_DIR/compose/phase-1/.env"
COMPOSE_FILE="$ROOT_DIR/phases/phase-1/compose.yml"
COMPOSE_PROJECT="ektisis-phase-1a"
YES="false"

cd "$ROOT_DIR"

usage() {
  cat <<'EOF_USAGE'
Usage:
  bash phases/phase-1/reset.sh [--yes]

This returns the machine to the post-Phase-0 baseline, as if Phase 1 had not been executed.

It removes:
  - Phase 1 containers and Compose network
  - Phase 1 generated config
  - Phase 1 service data
  - Phase 1 workspace and logs
  - local UFW rules opened by Phase 1

It keeps:
  - operating system setup
  - SSH
  - Docker
  - repository clone
  - Phase 0 baseline
EOF_USAGE
}

while [ "$#" -gt 0 ]; do
  case "$1" in
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
  if [ "$YES" = "true" ]; then
    return 0
  fi

  echo "This will remove Phase 1 runtime config and data, returning the machine to the post-Phase-0 baseline."
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

  if rm -r -f "$path" 2>/dev/null; then
    return 0
  fi

  sudo -- rm -r -f "$path"
}

remove_ufw_rule() {
  local port="$1"

  if ! command -v ufw >/dev/null 2>&1; then
    return 0
  fi

  sudo ufw delete allow "${port}/tcp" >/dev/null 2>&1 || true
}

echo "== Ektisis Phase 1 Reset =="
echo "Target: post-Phase-0 baseline"
echo

if ! confirm; then
  echo "Canceled."
  exit 1
fi

compose_down

remove_path "$RUNTIME_DIR/compose/phase-1"
remove_path "$RUNTIME_DIR/compose/phase-1a"
remove_path "$RUNTIME_DIR/data/postgres"
remove_path "$RUNTIME_DIR/data/gitea"
remove_path "$RUNTIME_DIR/data/freellmapi"
remove_path "$RUNTIME_DIR/data/redis"
remove_path "$RUNTIME_DIR/data/openhands"
remove_path "$RUNTIME_DIR/projects"
remove_path "$RUNTIME_DIR/logs/phase-1"

remove_ufw_rule 2222
remove_ufw_rule 3000
remove_ufw_rule 3001
remove_ufw_rule 3002
remove_ufw_rule 4000

echo "Phase 1 was removed."
echo
echo "Current baseline: Phase 0 prepared machine."
echo "Next run:"
echo
echo "bash phases/phase-1/run.sh"
