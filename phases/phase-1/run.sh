#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
RUNTIME_DIR="${EKTISIS_RUNTIME_DIR:-$HOME/ektisis-runtime}"
PHASE_RUNTIME_DIR="$RUNTIME_DIR/compose/phase-1"
ENV_FILE="$PHASE_RUNTIME_DIR/.env"
LITELLM_CONFIG_FILE="$PHASE_RUNTIME_DIR/litellm-config.yaml"
COMPOSE_FILE="$ROOT_DIR/phases/phase-1/compose.yml"
COMPOSE_PROJECT="ektisis-phase-1a"
LEGACY_ENV_FILE="$RUNTIME_DIR/compose/phase-1a/.env"
PASS=0
FAIL=0

cd "$ROOT_DIR"

ok() {
  echo "OK: $1"
  PASS=$((PASS + 1))
}

fail() {
  echo "FAIL: $1"
  FAIL=$((FAIL + 1))
}

section() {
  echo
  echo "$1"
}

random_hex() {
  if command -v openssl >/dev/null 2>&1; then
    openssl rand -hex 24
  else
    date +%s%N | sha256sum | awk '{print $1}'
  fi
}

get_env_value() {
  local key="$1"
  if [ -f "$ENV_FILE" ]; then
    awk -F= -v k="$key" '$1 == k {print substr($0, length(k) + 2); exit}' "$ENV_FILE"
  fi
}

set_env_if_missing() {
  local key="$1"
  local value="$2"
  if ! grep -q "^${key}=" "$ENV_FILE" 2>/dev/null; then
    printf '%s=%s\n' "$key" "$value" >> "$ENV_FILE"
  fi
}

prepare_runtime() {
  mkdir -p "$PHASE_RUNTIME_DIR"
  mkdir -p "$RUNTIME_DIR/data/postgres"
  mkdir -p "$RUNTIME_DIR/data/gitea"
  mkdir -p "$RUNTIME_DIR/data/litellm-postgres"
  mkdir -p "$RUNTIME_DIR/data/redis"
  mkdir -p "$RUNTIME_DIR/data/openhands"
  mkdir -p "$RUNTIME_DIR/projects"
  mkdir -p "$RUNTIME_DIR/logs/phase-1"

  if [ ! -f "$ENV_FILE" ] && [ -f "$LEGACY_ENV_FILE" ]; then
    cp "$LEGACY_ENV_FILE" "$ENV_FILE"
    chmod 600 "$ENV_FILE"
    echo "OK: reused existing Gitea environment from previous Phase 1 layout."
  fi

  if [ ! -f "$ENV_FILE" ]; then
    local local_ip public_ip domain postgres_password

    local_ip="$(hostname -I 2>/dev/null | awk '{print $1}' || true)"
    [ -z "$local_ip" ] && local_ip="localhost"

    public_ip=""
    if command -v curl >/dev/null 2>&1; then
      public_ip="$(curl -fsS --max-time 3 https://api.ipify.org 2>/dev/null || true)"
    fi

    domain="$local_ip"
    [ -n "$public_ip" ] && domain="$public_ip"

    postgres_password="$(random_hex)"

    cat > "$ENV_FILE" <<EOF_ENV
EKTISIS_RUNTIME_DIR=$RUNTIME_DIR
POSTGRES_IMAGE=postgres:16-alpine
POSTGRES_DB=gitea
POSTGRES_USER=gitea
POSTGRES_PASSWORD=$postgres_password
GITEA_IMAGE=gitea/gitea:latest
GITEA_HTTP_PORT=3000
GITEA_SSH_PORT=2222
GITEA_DOMAIN=$domain
GITEA_SSH_DOMAIN=$domain
GITEA_ROOT_URL=http://$domain:3000/
GITEA_USER_UID=$(id -u)
GITEA_USER_GID=$(id -g)
EOF_ENV
    chmod 600 "$ENV_FILE"
    echo "OK: created Phase 1 environment file."
  else
    echo "OK: using existing Phase 1 environment file."
  fi

  set_env_if_missing LITELLM_POSTGRES_IMAGE postgres:16-alpine
  set_env_if_missing LITELLM_POSTGRES_DB litellm
  set_env_if_missing LITELLM_POSTGRES_USER litellm
  set_env_if_missing LITELLM_POSTGRES_PASSWORD "$(random_hex)"
  set_env_if_missing LITELLM_IMAGE docker.litellm.ai/berriai/litellm:main-latest
  set_env_if_missing LITELLM_PORT 4000
  set_env_if_missing LITELLM_MASTER_KEY "sk-$(random_hex)"
  set_env_if_missing LITELLM_SALT_KEY "sk-$(random_hex)"
  set_env_if_missing REDIS_IMAGE redis:7-alpine
  set_env_if_missing OPENHANDS_IMAGE docker.all-hands.dev/all-hands-ai/openhands:latest
  set_env_if_missing OPENHANDS_SANDBOX_IMAGE docker.all-hands.dev/all-hands-ai/runtime:latest
  set_env_if_missing OPENHANDS_PORT 3002
  set_env_if_missing OPENHANDS_LLM_MODEL ektisis-free
  set_env_if_missing FREE_LLM_API_BASE http://freellmapi:3001/v1
  set_env_if_missing FREE_LLM_API_KEY sk-placeholder

  if [ ! -f "$LITELLM_CONFIG_FILE" ]; then
    cat > "$LITELLM_CONFIG_FILE" <<'EOF_CONFIG'
model_list:
  - model_name: ektisis-free
    litellm_params:
      model: openai/ektisis-free
      api_base: os.environ/FREE_LLM_API_BASE
      api_key: os.environ/FREE_LLM_API_KEY

general_settings:
  master_key: os.environ/LITELLM_MASTER_KEY
  database_url: os.environ/DATABASE_URL
EOF_CONFIG
    echo "OK: created LiteLLM config file."
  else
    echo "OK: using existing LiteLLM config file."
  fi
}

validate_phase0() {
  if bash phases/phase-0/validate.sh; then
    ok "Phase 0 validation passed"
  else
    fail "Phase 0 validation failed"
  fi
}

validate_prerequisites() {
  [ "$(id -u)" -ne 0 ] && ok "running as non-root user" || fail "do not run this script as root"
  [ -f "$COMPOSE_FILE" ] && ok "compose file exists" || fail "missing compose file: $COMPOSE_FILE"
  docker ps >/dev/null 2>&1 && ok "Docker works without sudo" || fail "Docker does not work without sudo"
  docker compose version >/dev/null 2>&1 && ok "Docker Compose works" || fail "Docker Compose is not available"
  command -v curl >/dev/null 2>&1 && ok "curl command found" || fail "curl command not found"
}

start_stack() {
  docker compose --env-file "$ENV_FILE" -f "$COMPOSE_FILE" -p "$COMPOSE_PROJECT" up -d
}

container_running() {
  local name="$1"
  [ "$(docker inspect -f '{{.State.Running}}' "$name" 2>/dev/null || echo false)" = "true" ]
}

container_health() {
  local name="$1"
  docker inspect -f '{{if .State.Health}}{{.State.Health.Status}}{{else}}none{{end}}' "$name" 2>/dev/null || echo unknown
}

validate_stack() {
  local gitea_port litellm_port openhands_port

  gitea_port="$(get_env_value GITEA_HTTP_PORT)"
  litellm_port="$(get_env_value LITELLM_PORT)"
  openhands_port="$(get_env_value OPENHANDS_PORT)"
  [ -z "$gitea_port" ] && gitea_port="3000"
  [ -z "$litellm_port" ] && litellm_port="4000"
  [ -z "$openhands_port" ] && openhands_port="3002"

  docker compose --env-file "$ENV_FILE" -f "$COMPOSE_FILE" -p "$COMPOSE_PROJECT" ps >/dev/null 2>&1 \
    && ok "Compose project can be inspected" \
    || fail "Compose project cannot be inspected"

  container_running ektisis-postgres && ok "Gitea PostgreSQL container is running" || fail "Gitea PostgreSQL container is not running"
  [ "$(container_health ektisis-postgres)" = "healthy" ] && ok "Gitea PostgreSQL is healthy" || fail "Gitea PostgreSQL is not healthy: $(container_health ektisis-postgres)"

  container_running ektisis-gitea && ok "Gitea container is running" || fail "Gitea container is not running"
  if curl -fsS --max-time 10 "http://127.0.0.1:$gitea_port/" >/dev/null 2>&1; then
    ok "Gitea HTTP responds locally on port $gitea_port"
  else
    fail "Gitea HTTP does not respond locally on port $gitea_port"
  fi

  container_running ektisis-litellm-postgres && ok "LiteLLM PostgreSQL container is running" || fail "LiteLLM PostgreSQL container is not running"
  [ "$(container_health ektisis-litellm-postgres)" = "healthy" ] && ok "LiteLLM PostgreSQL is healthy" || fail "LiteLLM PostgreSQL is not healthy: $(container_health ektisis-litellm-postgres)"

  container_running ektisis-litellm && ok "LiteLLM container is running" || fail "LiteLLM container is not running"
  if curl -fsS --max-time 10 "http://127.0.0.1:$litellm_port/health/readiness" >/dev/null 2>&1; then
    ok "LiteLLM readiness endpoint responds locally on port $litellm_port"
  else
    fail "LiteLLM readiness endpoint does not respond locally on port $litellm_port"
  fi

  container_running ektisis-redis && ok "Redis container is running" || fail "Redis container is not running"
  [ "$(container_health ektisis-redis)" = "healthy" ] && ok "Redis is healthy" || fail "Redis is not healthy: $(container_health ektisis-redis)"

  container_running ektisis-openhands && ok "OpenHands container is running" || fail "OpenHands container is not running"
  if curl -fsS --max-time 10 "http://127.0.0.1:$openhands_port/" >/dev/null 2>&1; then
    ok "OpenHands HTTP responds locally on port $openhands_port"
  else
    fail "OpenHands HTTP does not respond locally on port $openhands_port"
  fi
}

print_access_urls() {
  local root_url litellm_port openhands_port public_ip local_ip
  root_url="$(get_env_value GITEA_ROOT_URL)"
  litellm_port="$(get_env_value LITELLM_PORT)"
  openhands_port="$(get_env_value OPENHANDS_PORT)"
  [ -z "$litellm_port" ] && litellm_port="4000"
  [ -z "$openhands_port" ] && openhands_port="3002"

  local_ip="$(hostname -I 2>/dev/null | awk '{print $1}' || true)"
  public_ip="$(curl -fsS --max-time 3 https://api.ipify.org 2>/dev/null || true)"

  echo
  echo "Service URLs:"
  echo
  [ -n "$root_url" ] && echo "Gitea: $root_url"
  if [ -n "$public_ip" ]; then
    echo "LiteLLM: http://$public_ip:$litellm_port/"
    echo "OpenHands: http://$public_ip:$openhands_port/"
  elif [ -n "$local_ip" ]; then
    echo "LiteLLM: http://$local_ip:$litellm_port/"
    echo "OpenHands: http://$local_ip:$openhands_port/"
  fi
}

print_result() {
  echo
  echo "PASS: $PASS"
  echo "FAIL: $FAIL"
  echo

  if [ "$FAIL" -eq 0 ]; then
    echo "Phase 1 completed: the factory Docker Compose stack is running."
    print_access_urls
    exit 0
  fi

  echo "Phase 1 failed. Inspect service logs with:"
  echo
  echo "docker compose --env-file $ENV_FILE -f $COMPOSE_FILE -p $COMPOSE_PROJECT logs --tail=100"
  exit 1
}

echo "== Ektisis Phase 1 — Factory Docker Compose Stack =="
echo

section "Step 1: validate Phase 0 baseline."
validate_phase0

section "Step 2: validate Phase 1 prerequisites."
validate_prerequisites

section "Step 3: prepare runtime configuration."
prepare_runtime

section "Step 4: start all services with Docker Compose."
start_stack
ok "Docker Compose up completed"

section "Step 5: validate service health."
validate_stack

print_result
