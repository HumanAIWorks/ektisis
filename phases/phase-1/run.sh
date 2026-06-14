#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
RUNTIME_DIR="${EKTISIS_RUNTIME_DIR:-$HOME/ektisis-runtime}"
PHASE_RUNTIME_DIR="$RUNTIME_DIR/compose/phase-1"
LEGACY_ENV_FILE="$RUNTIME_DIR/compose/phase-1a/.env"
ENV_FILE="$PHASE_RUNTIME_DIR/.env"
COMPOSE_FILE="$PHASE_RUNTIME_DIR/compose.yml"
COMPOSE_PROJECT="ektisis-phase-1a"
WORK_DIR="$RUNTIME_DIR/projects/phase-1-git-smoke"
RUN_ID="$(date +%s)"
TEMP_USER="ektisis-smoke-user-${RUN_ID}"
TEMP_EMAIL="${TEMP_USER}@example.local"
TEMP_PASS="$(openssl rand -base64 24 2>/dev/null | tr -d '\n' | tr '/+' 'Aa' || date +%s%N | sha256sum | awk '{print $1}')"
TEMP_ORG="ektisis-smoke-${RUN_ID}"
TEMP_REPO="git-flow-check"
TEST_FILE="phase-1-git-smoke-test.txt"
TARGET_DIR="$WORK_DIR/$TEMP_ORG/$TEMP_REPO"
CREATED_USER=0
CREATED_ORG=0
CREATED_REPO=0
GITEA_BASE_URL=""
ASKPASS_FILE=""
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

load_env_value() {
  local key="$1"
  if [ -f "$ENV_FILE" ]; then
    awk -F= -v k="$key" '$1 == k {print substr($0, length(k) + 2); exit}' "$ENV_FILE"
  fi
}

write_compose_file() {
  cat > "$COMPOSE_FILE" <<'EOF_COMPOSE'
services:
  postgres:
    image: ${POSTGRES_IMAGE:-postgres:16-alpine}
    container_name: ektisis-postgres
    restart: unless-stopped
    environment:
      POSTGRES_DB: ${POSTGRES_DB:-gitea}
      POSTGRES_USER: ${POSTGRES_USER:-gitea}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD:?POSTGRES_PASSWORD is required}
    volumes:
      - ${EKTISIS_RUNTIME_DIR:?EKTISIS_RUNTIME_DIR is required}/data/postgres:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${POSTGRES_USER:-gitea} -d ${POSTGRES_DB:-gitea}"]
      interval: 10s
      timeout: 5s
      retries: 10
    networks:
      - ektisis

  gitea:
    image: ${GITEA_IMAGE:-gitea/gitea:latest}
    container_name: ektisis-gitea
    restart: unless-stopped
    depends_on:
      postgres:
        condition: service_healthy
    environment:
      USER_UID: ${GITEA_USER_UID:-1000}
      USER_GID: ${GITEA_USER_GID:-1000}
      GITEA__database__DB_TYPE: postgres
      GITEA__database__HOST: postgres:5432
      GITEA__database__NAME: ${POSTGRES_DB:-gitea}
      GITEA__database__USER: ${POSTGRES_USER:-gitea}
      GITEA__database__PASSWD: ${POSTGRES_PASSWORD:?POSTGRES_PASSWORD is required}
      GITEA__server__DOMAIN: ${GITEA_DOMAIN:-localhost}
      GITEA__server__ROOT_URL: ${GITEA_ROOT_URL:-http://localhost:3000/}
      GITEA__server__SSH_DOMAIN: ${GITEA_SSH_DOMAIN:-localhost}
      GITEA__server__SSH_PORT: ${GITEA_SSH_PORT:-2222}
      GITEA__server__SSH_LISTEN_PORT: 2222
      GITEA__server__START_SSH_SERVER: "true"
    ports:
      - "${GITEA_HTTP_PORT:-3000}:3000"
      - "${GITEA_SSH_PORT:-2222}:2222"
    volumes:
      - ${EKTISIS_RUNTIME_DIR:?EKTISIS_RUNTIME_DIR is required}/data/gitea:/data
    networks:
      - ektisis

networks:
  ektisis:
    name: ektisis-phase-1a
EOF_COMPOSE
}

prepare_environment() {
  mkdir -p "$PHASE_RUNTIME_DIR"
  mkdir -p "$RUNTIME_DIR/data/postgres"
  mkdir -p "$RUNTIME_DIR/data/gitea"
  mkdir -p "$RUNTIME_DIR/logs/phase-1"
  mkdir -p "$RUNTIME_DIR/projects"
  mkdir -p "$WORK_DIR"

  if [ ! -f "$ENV_FILE" ] && [ -f "$LEGACY_ENV_FILE" ]; then
    cp "$LEGACY_ENV_FILE" "$ENV_FILE"
    chmod 600 "$ENV_FILE"
    echo "OK: reused existing Gitea environment from previous Phase 1A layout."
  fi

  if [ ! -f "$ENV_FILE" ]; then
    local local_ip public_egress_ip domain password

    local_ip="$(hostname -I 2>/dev/null | awk '{print $1}' || true)"
    [ -z "$local_ip" ] && local_ip="localhost"

    public_egress_ip=""
    if command -v curl >/dev/null 2>&1; then
      public_egress_ip="$(curl -fsS --max-time 3 https://api.ipify.org 2>/dev/null || true)"
    fi

    domain="$local_ip"
    [ -n "$public_egress_ip" ] && domain="$public_egress_ip"

    if command -v openssl >/dev/null 2>&1; then
      password="$(openssl rand -hex 24)"
    else
      password="$(date +%s%N | sha256sum | awk '{print $1}')"
    fi

    cat > "$ENV_FILE" <<EOF_ENV
EKTISIS_RUNTIME_DIR=$RUNTIME_DIR
POSTGRES_IMAGE=postgres:16-alpine
POSTGRES_DB=gitea
POSTGRES_USER=gitea
POSTGRES_PASSWORD=$password
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
    echo "OK: created Gitea environment file."
  else
    echo "OK: using existing Gitea environment file."
  fi

  write_compose_file
  echo "OK: generated runtime Docker Compose file."
}

validate_machine_prerequisites() {
  [ "$(id -u)" -ne 0 ] && ok "running as non-root user" || fail "do not run this script as root"
  [ -d "$RUNTIME_DIR" ] && ok "runtime directory exists" || fail "runtime directory missing: $RUNTIME_DIR"

  if docker ps >/dev/null 2>&1; then
    ok "Docker works without sudo"
  else
    fail "Docker does not work without sudo"
  fi

  if docker compose version >/dev/null 2>&1; then
    ok "Docker Compose works"
  else
    fail "Docker Compose is not available"
  fi

  if command -v git >/dev/null 2>&1; then
    ok "git command found"
  else
    fail "git command not found"
  fi

  if command -v curl >/dev/null 2>&1; then
    ok "curl command found"
  else
    fail "curl command not found"
  fi
}

start_services() {
  docker compose --env-file "$ENV_FILE" -f "$COMPOSE_FILE" -p "$COMPOSE_PROJECT" up -d
}

validate_services() {
  local http_port postgres_running gitea_running postgres_health

  http_port="$(load_env_value GITEA_HTTP_PORT || true)"
  [ -z "$http_port" ] && http_port="3000"

  if docker compose --env-file "$ENV_FILE" -f "$COMPOSE_FILE" -p "$COMPOSE_PROJECT" ps >/dev/null 2>&1; then
    ok "Compose project can be inspected"
  else
    fail "Compose project cannot be inspected"
  fi

  postgres_running="$(docker inspect -f '{{.State.Running}}' ektisis-postgres 2>/dev/null || echo false)"
  gitea_running="$(docker inspect -f '{{.State.Running}}' ektisis-gitea 2>/dev/null || echo false)"

  [ "$postgres_running" = "true" ] && ok "PostgreSQL container is running" || fail "PostgreSQL container is not running"
  [ "$gitea_running" = "true" ] && ok "Gitea container is running" || fail "Gitea container is not running"

  postgres_health="$(docker inspect -f '{{if .State.Health}}{{.State.Health.Status}}{{else}}none{{end}}' ektisis-postgres 2>/dev/null || echo unknown)"
  [ "$postgres_health" = "healthy" ] && ok "PostgreSQL is healthy" || fail "PostgreSQL is not healthy: $postgres_health"

  if curl -fsS --max-time 10 "http://127.0.0.1:$http_port/" >/dev/null 2>&1; then
    ok "Gitea HTTP responds locally on port $http_port"
  else
    fail "Gitea HTTP does not respond locally on port $http_port"
  fi

  [ -d "$RUNTIME_DIR/data/postgres" ] && ok "PostgreSQL data directory exists" || fail "missing PostgreSQL data directory"
  [ -d "$RUNTIME_DIR/data/gitea" ] && ok "Gitea data directory exists" || fail "missing Gitea data directory"
  [ -d "$RUNTIME_DIR/data/gitea/gitea" ] && ok "Gitea work directory exists" || fail "missing Gitea work directory"
}

check_access() {
  local http_port ssh_port local_ip public_egress_ip local_firewall_ok ufw_status listen_info root_url
  http_port="$(load_env_value GITEA_HTTP_PORT || true)"
  ssh_port="$(load_env_value GITEA_SSH_PORT || true)"
  root_url="$(load_env_value GITEA_ROOT_URL || true)"
  [ -z "$http_port" ] && http_port="3000"
  [ -z "$ssh_port" ] && ssh_port="2222"

  local_ip="$(hostname -I 2>/dev/null | awk '{print $1}' || true)"
  [ -z "$local_ip" ] && local_ip="not detected"

  public_egress_ip="not detected"
  if command -v curl >/dev/null 2>&1; then
    value="$(curl -fsS --max-time 3 https://api.ipify.org 2>/dev/null || true)"
    [ -n "$value" ] && public_egress_ip="$value"
  fi

  echo "Detected access information:"
  echo "- Local IP: $local_ip"
  echo "- Public egress IP: $public_egress_ip"
  echo "- Gitea HTTP port: $http_port"
  echo "- Gitea SSH port: $ssh_port"

  if curl -fsS --max-time 5 "http://127.0.0.1:$http_port/" >/dev/null 2>&1; then
    ok "Gitea responds inside this machine"
  else
    fail "Gitea does not respond inside this machine"
    return
  fi

  listen_info="$(ss -ltn 2>/dev/null | grep ":$http_port " || true)"
  [ -n "$listen_info" ] && ok "port $http_port is listening" || fail "port $http_port was not found in the listening port list"

  local_firewall_ok=0
  ufw_status="$(sudo -n ufw status 2>/dev/null || ufw status 2>/dev/null || true)"
  if printf '%s' "$ufw_status" | grep -qi 'Status: active'; then
    if printf '%s' "$ufw_status" | grep -qE "(^| )$http_port/tcp|$http_port"; then
      ok "local firewall appears to allow port $http_port"
      local_firewall_ok=1
    else
      fail "local firewall is active and port $http_port is not clearly allowed"
    fi
  else
    ok "local firewall is not active or could not be checked"
    local_firewall_ok=1
  fi

  echo
  echo "Browser URL to test:"
  echo
  if [ -n "$root_url" ]; then
    echo "$root_url"
  elif [ "$public_egress_ip" != "not detected" ]; then
    echo "http://$public_egress_ip:$http_port/"
  else
    echo "http://$local_ip:$http_port/"
  fi

  if [ "$local_firewall_ok" -eq 0 ]; then
    echo
    echo "If browser access fails, open the local firewall for Gitea HTTP port $http_port."
  fi
}

run_gitea_cli() {
  docker exec -u git ektisis-gitea gitea --config /data/gitea/conf/app.ini "$@"
}

api_call() {
  local method="$1"
  local path="$2"
  local data="${3:-}"
  local body_file status

  body_file="$(mktemp)"

  if [ -n "$data" ]; then
    status="$(curl -sS -u "$TEMP_USER:$TEMP_PASS" \
      -H 'Content-Type: application/json' \
      -X "$method" \
      -d "$data" \
      -o "$body_file" \
      -w '%{http_code}' \
      "$GITEA_BASE_URL/api/v1$path" || true)"
  else
    status="$(curl -sS -u "$TEMP_USER:$TEMP_PASS" \
      -X "$method" \
      -o "$body_file" \
      -w '%{http_code}' \
      "$GITEA_BASE_URL/api/v1$path" || true)"
  fi

  rm -f "$body_file"
  printf '%s' "$status"
}

cleanup() {
  if [ "$CREATED_REPO" -eq 1 ] || [ "$CREATED_ORG" -eq 1 ] || [ "$CREATED_USER" -eq 1 ] || [ -d "$WORK_DIR/$TEMP_ORG" ]; then
    echo
    echo "Cleaning Phase 1 temporary Git smoke test resources..."
  fi

  if [ "$CREATED_REPO" -eq 1 ]; then
    repo_status="$(api_call DELETE "/repos/$TEMP_ORG/$TEMP_REPO")"
    case "$repo_status" in
      204|404) echo "OK: temporary repository removed or already absent." ;;
      *) echo "WARN: temporary repository cleanup did not complete automatically." ;;
    esac
  fi

  if [ "$CREATED_ORG" -eq 1 ]; then
    org_status="$(api_call DELETE "/orgs/$TEMP_ORG")"
    case "$org_status" in
      204|404) echo "OK: temporary organization removed or already absent." ;;
      *) echo "WARN: temporary organization cleanup did not complete automatically." ;;
    esac
  fi

  if [ "$CREATED_USER" -eq 1 ]; then
    if run_gitea_cli admin user delete --username "$TEMP_USER" --purge >/dev/null 2>&1; then
      echo "OK: temporary Gitea user removed."
    else
      echo "WARN: temporary Gitea user cleanup did not complete automatically."
    fi
  fi

  rm -rf "$WORK_DIR/$TEMP_ORG"

  if [ -n "$ASKPASS_FILE" ]; then
    rm -f "$ASKPASS_FILE"
  fi
}
trap cleanup EXIT

run_git_smoke_test() {
  local org_status repo_status repo_url

  GITEA_BASE_URL="$(load_env_value GITEA_ROOT_URL || true)"
  [ -z "$GITEA_BASE_URL" ] && GITEA_BASE_URL="http://127.0.0.1:3000/"
  GITEA_BASE_URL="${GITEA_BASE_URL%/}"

  echo "Creating temporary Gitea user."
  if ! run_gitea_cli admin user create \
    --username "$TEMP_USER" \
    --password "$TEMP_PASS" \
    --email "$TEMP_EMAIL" \
    --admin \
    --must-change-password=false >/dev/null; then
    fail "could not create temporary Gitea user"
    return
  fi
  CREATED_USER=1
  ok "temporary Gitea user created"

  org_status="$(api_call POST "/orgs" "{\"username\":\"$TEMP_ORG\",\"full_name\":\"Ektisis Phase 1 Git Smoke Test\",\"visibility\":\"private\"}")"
  if [ "$org_status" != "201" ]; then
    fail "could not create temporary organization"
    return
  fi
  CREATED_ORG=1
  ok "temporary organization created"

  repo_status="$(api_call POST "/orgs/$TEMP_ORG/repos" "{\"name\":\"$TEMP_REPO\",\"private\":true,\"auto_init\":true,\"default_branch\":\"main\"}")"
  if [ "$repo_status" != "201" ]; then
    fail "could not create temporary repository"
    return
  fi
  CREATED_REPO=1
  ok "temporary repository created"

  mkdir -p "$WORK_DIR/$TEMP_ORG"
  repo_url="$GITEA_BASE_URL/$TEMP_ORG/$TEMP_REPO.git"

  ASKPASS_FILE="$(mktemp)"
  cat > "$ASKPASS_FILE" <<'EOF_ASKPASS'
#!/usr/bin/env bash
case "$1" in
  *Username*) printf '%s\n' "$TEMP_USER" ;;
  *Password*) printf '%s\n' "$TEMP_PASS" ;;
  *) printf '\n' ;;
esac
EOF_ASKPASS
  chmod 700 "$ASKPASS_FILE"

  export TEMP_USER
  export TEMP_PASS
  export GIT_ASKPASS="$ASKPASS_FILE"
  export GIT_TERMINAL_PROMPT=0

  if ! git clone "$repo_url" "$TARGET_DIR"; then
    fail "Git clone failed"
    return
  fi
  ok "Git clone works"

  cd "$TARGET_DIR"
  git config user.name "Ektisis Smoke Test"
  git config user.email "ektisis-smoke-test@example.local"

  {
    echo "Ektisis Phase 1 Git smoke test"
    echo "Generated at: $(date '+%Y-%m-%d %H:%M:%S %z')"
  } > "$TEST_FILE"

  git add "$TEST_FILE"
  git commit -m "test: validate Phase 1 Git flow" >/dev/null
  ok "Git commit works"

  if ! git push; then
    fail "Git push failed"
    return
  fi
  ok "Git push works"

  cd "$ROOT_DIR"
}

print_result() {
  echo
  echo "PASS: $PASS"
  echo "FAIL: $FAIL"
  echo

  if [ "$FAIL" -eq 0 ]; then
    echo "Phase 1 completed: Gitea is installed and Git operations are validated."
    echo
    echo "Run next:"
    echo
    echo "bash phases/phase-2/run.sh"
    exit 0
  fi

  echo "Phase 1 failed. Fix the failed item above and run this script again."
  exit 1
}

echo "== Ektisis Phase 1 — Gitea =="
echo
echo "This single script installs and validates the Gitea Git server stack."
echo

section "Step 1: validate machine prerequisites."
validate_machine_prerequisites

section "Step 2: prepare Phase 1 runtime files."
prepare_environment

section "Step 3: start Gitea and PostgreSQL."
start_services
ok "Docker Compose started Gitea and PostgreSQL"

section "Step 4: validate Gitea and PostgreSQL health."
validate_services

section "Step 5: check Gitea access."
check_access

section "Step 6: validate Git operations with temporary resources."
run_git_smoke_test

print_result
