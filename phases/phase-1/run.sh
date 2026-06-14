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

random_hex_32() {
  if command -v openssl >/dev/null 2>&1; then
    openssl rand -hex 32
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

set_env_value() {
  local key="$1"
  local value="$2"
  if grep -q "^${key}=" "$ENV_FILE" 2>/dev/null; then
    sed -i "s|^${key}=.*|${key}=${value}|" "$ENV_FILE"
  else
    printf '%s=%s\n' "$key" "$value" >> "$ENV_FILE"
  fi
}

wait_http() {
  local name="$1"
  local url="$2"
  local attempts="${3:-60}"
  local delay="${4:-2}"
  local attempt

  for attempt in $(seq 1 "$attempts"); do
    if curl -fsS --max-time 5 "$url" >/dev/null 2>&1; then
      ok "$name responds"
      return 0
    fi
    sleep "$delay"
  done

  fail "$name does not respond: $url"
  return 1
}

prepare_runtime() {
  mkdir -p "$PHASE_RUNTIME_DIR"
  mkdir -p "$RUNTIME_DIR/data/postgres"
  mkdir -p "$RUNTIME_DIR/data/gitea"
  mkdir -p "$RUNTIME_DIR/data/freellmapi"
  mkdir -p "$RUNTIME_DIR/data/redis"
  mkdir -p "$RUNTIME_DIR/data/openhands"
  mkdir -p "$RUNTIME_DIR/projects"
  mkdir -p "$RUNTIME_DIR/logs/phase-1"

  chmod 0777 "$RUNTIME_DIR/data/freellmapi" || true

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

  set_env_if_missing LITELLM_DB litellm
  set_env_if_missing LITELLM_IMAGE docker.litellm.ai/berriai/litellm:main-latest
  set_env_if_missing LITELLM_PORT 4000
  set_env_if_missing LITELLM_MASTER_KEY "sk-$(random_hex)"
  set_env_if_missing LITELLM_SALT_KEY "sk-$(random_hex)"
  set_env_if_missing FREELLMAPI_PORT 3001
  set_env_if_missing FREELLMAPI_HOST_BIND 127.0.0.1
  set_env_if_missing FREELLMAPI_ENCRYPTION_KEY "$(random_hex_32)"
  set_env_if_missing FREELLMAPI_REQUEST_ANALYTICS_RETENTION_DAYS 90
  set_env_if_missing FREELLMAPI_REQUEST_ANALYTICS_MAX_ROWS 100000
  set_env_if_missing REDIS_IMAGE redis:7-alpine
  set_env_value OPENHANDS_IMAGE docker.openhands.dev/openhands/openhands:1.8
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

configure_firewall() {
  local gitea_port litellm_port openhands_port ufw_status

  if ! command -v ufw >/dev/null 2>&1; then
    ok "UFW not installed; skipping local firewall configuration"
    return 0
  fi

  if ! sudo -n true 2>/dev/null; then
    echo "sudo may ask for your password to configure UFW."
  fi

  ufw_status="$(sudo ufw status 2>/dev/null || true)"
  if ! printf '%s' "$ufw_status" | grep -qi 'Status: active'; then
    ok "UFW is not active; no local firewall ports to open"
    return 0
  fi

  gitea_port="$(get_env_value GITEA_HTTP_PORT)"
  litellm_port="$(get_env_value LITELLM_PORT)"
  openhands_port="$(get_env_value OPENHANDS_PORT)"
  [ -z "$gitea_port" ] && gitea_port="3000"
  [ -z "$litellm_port" ] && litellm_port="4000"
  [ -z "$openhands_port" ] && openhands_port="3002"

  sudo ufw allow "${gitea_port}/tcp" comment 'Ektisis Gitea' >/dev/null
  ok "UFW allows Gitea port $gitea_port/tcp"

  sudo ufw allow "${litellm_port}/tcp" comment 'Ektisis LiteLLM' >/dev/null
  ok "UFW allows LiteLLM port $litellm_port/tcp"

  sudo ufw allow "${openhands_port}/tcp" comment 'Ektisis OpenHands' >/dev/null
  ok "UFW allows OpenHands port $openhands_port/tcp"

  ok "FreeLLMAPI port is not opened publicly"
}

start_postgres() {
  docker compose --env-file "$ENV_FILE" -f "$COMPOSE_FILE" -p "$COMPOSE_PROJECT" up -d postgres
}

wait_for_postgres() {
  local attempt postgres_user postgres_db
  postgres_user="$(get_env_value POSTGRES_USER)"
  postgres_db="$(get_env_value POSTGRES_DB)"
  [ -z "$postgres_user" ] && postgres_user="gitea"
  [ -z "$postgres_db" ] && postgres_db="gitea"

  for attempt in $(seq 1 30); do
    if docker exec ektisis-postgres pg_isready -U "$postgres_user" -d "$postgres_db" >/dev/null 2>&1; then
      ok "PostgreSQL is ready"
      return 0
    fi
    sleep 2
  done

  fail "PostgreSQL did not become ready"
  return 1
}

ensure_litellm_database() {
  local postgres_user postgres_password litellm_db exists
  postgres_user="$(get_env_value POSTGRES_USER)"
  postgres_password="$(get_env_value POSTGRES_PASSWORD)"
  litellm_db="$(get_env_value LITELLM_DB)"
  [ -z "$postgres_user" ] && postgres_user="gitea"
  [ -z "$litellm_db" ] && litellm_db="litellm"

  exists="$(docker exec -e PGPASSWORD="$postgres_password" ektisis-postgres psql -U "$postgres_user" -d postgres -tAc "SELECT 1 FROM pg_database WHERE datname='${litellm_db}'" 2>/dev/null || true)"

  if [ "$exists" = "1" ]; then
    ok "LiteLLM database already exists in shared PostgreSQL"
    return 0
  fi

  if docker exec -e PGPASSWORD="$postgres_password" ektisis-postgres createdb -U "$postgres_user" "$litellm_db" >/dev/null 2>&1; then
    ok "LiteLLM database created in shared PostgreSQL"
  else
    fail "could not create LiteLLM database in shared PostgreSQL"
  fi
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
  local gitea_port freellmapi_port litellm_port openhands_port

  gitea_port="$(get_env_value GITEA_HTTP_PORT)"
  freellmapi_port="$(get_env_value FREELLMAPI_PORT)"
  litellm_port="$(get_env_value LITELLM_PORT)"
  openhands_port="$(get_env_value OPENHANDS_PORT)"
  [ -z "$gitea_port" ] && gitea_port="3000"
  [ -z "$freellmapi_port" ] && freellmapi_port="3001"
  [ -z "$litellm_port" ] && litellm_port="4000"
  [ -z "$openhands_port" ] && openhands_port="3002"

  docker compose --env-file "$ENV_FILE" -f "$COMPOSE_FILE" -p "$COMPOSE_PROJECT" ps >/dev/null 2>&1 \
    && ok "Compose project can be inspected" \
    || fail "Compose project cannot be inspected"

  container_running ektisis-postgres && ok "shared PostgreSQL container is running" || fail "shared PostgreSQL container is not running"
  [ "$(container_health ektisis-postgres)" = "healthy" ] && ok "shared PostgreSQL is healthy" || fail "shared PostgreSQL is not healthy: $(container_health ektisis-postgres)"

  container_running ektisis-gitea && ok "Gitea container is running" || fail "Gitea container is not running"
  wait_http "Gitea HTTP" "http://127.0.0.1:$gitea_port/" 30 2 || true

  container_running ektisis-freellmapi && ok "FreeLLMAPI container is running" || fail "FreeLLMAPI container is not running"
  wait_http "FreeLLMAPI ping endpoint" "http://127.0.0.1:$freellmapi_port/api/ping" 60 2 || true

  container_running ektisis-litellm && ok "LiteLLM container is running" || fail "LiteLLM container is not running"
  wait_http "LiteLLM readiness endpoint" "http://127.0.0.1:$litellm_port/health/readiness" 60 2 || true

  container_running ektisis-redis && ok "Redis container is running" || fail "Redis container is not running"
  [ "$(container_health ektisis-redis)" = "healthy" ] && ok "Redis is healthy" || fail "Redis is not healthy: $(container_health ektisis-redis)"

  container_running ektisis-openhands && ok "OpenHands container is running" || fail "OpenHands container is not running"
  wait_http "OpenHands HTTP" "http://127.0.0.1:$openhands_port/" 60 2 || true
}

print_access_urls() {
  local root_url freellmapi_port litellm_port openhands_port public_ip local_ip
  root_url="$(get_env_value GITEA_ROOT_URL)"
  freellmapi_port="$(get_env_value FREELLMAPI_PORT)"
  litellm_port="$(get_env_value LITELLM_PORT)"
  openhands_port="$(get_env_value OPENHANDS_PORT)"
  [ -z "$freellmapi_port" ] && freellmapi_port="3001"
  [ -z "$litellm_port" ] && litellm_port="4000"
  [ -z "$openhands_port" ] && openhands_port="3002"

  local_ip="$(hostname -I 2>/dev/null | awk '{print $1}' || true)"
  public_ip="$(curl -fsS --max-time 3 https://api.ipify.org 2>/dev/null || true)"

  echo
  echo "Service URLs:"
  echo
  [ -n "$root_url" ] && echo "Gitea: $root_url"
  echo "FreeLLMAPI: http://127.0.0.1:$freellmapi_port/"
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

section "Step 4: configure local firewall."
configure_firewall

section "Step 5: start shared PostgreSQL."
start_postgres
wait_for_postgres
ensure_litellm_database

section "Step 6: start all services with Docker Compose."
start_stack
ok "Docker Compose up completed"

section "Step 7: validate service health."
validate_stack

print_result
