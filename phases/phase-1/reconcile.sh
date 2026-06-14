#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
RUNTIME_DIR="${EKTISIS_RUNTIME_DIR:-$HOME/ektisis-runtime}"
ENV_FILE="$RUNTIME_DIR/compose/phase-1/.env"
COMPOSE_FILE="$ROOT_DIR/phases/phase-1/compose.yml"
COMPOSE_PROJECT="ektisis-phase-1a"

cd "$ROOT_DIR"

get_env_value() {
  local key="$1"
  if [ -f "$ENV_FILE" ]; then
    awk -F= -v k="$key" '$1 == k {print substr($0, length(k) + 2); exit}' "$ENV_FILE"
  fi
}

container_env_value() {
  local container="$1"
  local key="$2"
  if docker inspect "$container" >/dev/null 2>&1; then
    docker exec "$container" printenv "$key" 2>/dev/null || true
  fi
}

recreate_service() {
  local service="$1"
  docker compose \
    --env-file "$ENV_FILE" \
    -f "$COMPOSE_FILE" \
    -p "$COMPOSE_PROJECT" \
    up -d --force-recreate "$service"
}

require_file() {
  if [ ! -f "$ENV_FILE" ]; then
    echo "FAIL: missing runtime environment file: $ENV_FILE"
    echo
    echo "Run first:"
    echo "bash phases/phase-1/run.sh"
    exit 1
  fi
}

check_litellm_env() {
  local expected_master actual_master expected_ui_password actual_ui_password
  expected_master="$(get_env_value LITELLM_MASTER_KEY)"
  expected_ui_password="$(get_env_value UI_PASSWORD)"
  actual_master="$(container_env_value ektisis-litellm LITELLM_MASTER_KEY)"
  actual_ui_password="$(container_env_value ektisis-litellm UI_PASSWORD)"

  if [ -z "$actual_master" ]; then
    echo "LiteLLM container is missing or not ready; recreating LiteLLM."
    recreate_service litellm
    return 0
  fi

  if [ "$expected_master" != "$actual_master" ]; then
    echo "LiteLLM master key differs between .env and container; recreating LiteLLM."
    recreate_service litellm
    return 0
  fi

  if [ -n "$expected_ui_password" ] && [ "$expected_ui_password" != "$actual_ui_password" ]; then
    echo "LiteLLM UI password differs between .env and container; recreating LiteLLM."
    recreate_service litellm
    return 0
  fi

  echo "OK: LiteLLM container environment matches .env."
}

check_openhands_env() {
  local expected_key actual_key
  expected_key="$(get_env_value LITELLM_MASTER_KEY)"
  actual_key="$(container_env_value ektisis-openhands LLM_API_KEY)"

  if [ -z "$actual_key" ]; then
    echo "OpenHands container is missing or not ready; recreating OpenHands."
    recreate_service openhands
    return 0
  fi

  if [ "$expected_key" != "$actual_key" ]; then
    echo "OpenHands LLM_API_KEY differs from LiteLLM master key in .env; recreating OpenHands."
    recreate_service openhands
    return 0
  fi

  echo "OK: OpenHands container environment matches .env."
}

verify() {
  echo
  echo "Verification:"
  echo
  echo "LiteLLM .env key:      $(get_env_value LITELLM_MASTER_KEY)"
  echo "LiteLLM container key: $(container_env_value ektisis-litellm LITELLM_MASTER_KEY)"
  echo "OpenHands API key:     $(container_env_value ektisis-openhands LLM_API_KEY)"
}

echo "== Ektisis Phase 1 — Reconcile Runtime =="
echo

require_file
check_litellm_env
check_openhands_env
verify

echo
echo "Runtime reconciliation completed."
