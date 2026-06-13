#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
ENV_FILE="$HOME/ektisis-runtime/compose/phase-1a/.env"
WORK_DIR="$HOME/ektisis-runtime/projects/phase-1b-auto-smoke"
RUN_ID="$(date +%s)"
TEMP_USER="ektisis-smoke-user-${RUN_ID}"
TEMP_EMAIL="${TEMP_USER}@example.local"
TEMP_PASS="$(openssl rand -base64 24 | tr -d '\n' | tr '/+' 'Aa')"
TEMP_ORG="ektisis-smoke-${RUN_ID}"
TEMP_REPO="git-flow-check"
TEST_FILE="phase-1b-smoke-test.txt"
TARGET_DIR="$WORK_DIR/$TEMP_ORG/$TEMP_REPO"
CREATED_USER=0
CREATED_ORG=0
CREATED_REPO=0
GITEA_BASE_URL=""
ASKPASS_FILE=""

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
  echo
  echo "Cleaning Phase 1B temporary resources..."

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
  echo "OK: temporary local clone removed."

  if [ -n "$ASKPASS_FILE" ]; then
    rm -f "$ASKPASS_FILE"
  fi
}
trap cleanup EXIT

if [ ! -f "$ENV_FILE" ]; then
  echo "Phase 1A environment file was not found."
  echo
  echo "Run Phase 1A first."
  exit 1
fi

# shellcheck disable=SC1091
source "$ENV_FILE"

GITEA_BASE_URL="${GITEA_ROOT_URL:-http://127.0.0.1:3000/}"
GITEA_BASE_URL="${GITEA_BASE_URL%/}"

cd "$ROOT_DIR"

echo "== Ektisis Phase 1B Automated Gitea Smoke Test =="
echo
echo "This phase creates temporary Gitea resources, validates Git clone/commit/push, and removes the temporary resources at the end."
echo

echo "Step 1: validate Phase 1A services."
if ! bash phases/phase-1a/validate.sh; then
  echo
  echo "Phase 1A validation failed. Fix Phase 1A before running Phase 1B."
  exit 1
fi

if ! bash phases/phase-1a/check-access.sh >/dev/null; then
  echo
  echo "Phase 1A access check failed. Follow the troubleshooting document suggested by the access check."
  exit 1
fi

echo
echo "Step 2: validate Phase 1B prerequisites."
if ! bash phases/phase-1b/validate.sh; then
  echo
  echo "Phase 1B prerequisite validation failed. Fix the reported item and run this script again."
  exit 1
fi

echo
echo "Step 3: create temporary Gitea user for automation."
if ! run_gitea_cli admin user create \
  --username "$TEMP_USER" \
  --password "$TEMP_PASS" \
  --email "$TEMP_EMAIL" \
  --admin \
  --must-change-password=false >/dev/null; then
  echo "Could not create the temporary Gitea user."
  exit 1
fi
CREATED_USER=1
echo "OK: temporary Gitea user created."

echo
echo "Step 4: create temporary organization and repository."
org_status="$(api_call POST "/orgs" "{\"username\":\"$TEMP_ORG\",\"full_name\":\"Ektisis Phase 1B Smoke Test\",\"visibility\":\"private\"}")"
if [ "$org_status" != "201" ]; then
  echo "Could not create the temporary organization."
  exit 1
fi
CREATED_ORG=1

repo_status="$(api_call POST "/orgs/$TEMP_ORG/repos" "{\"name\":\"$TEMP_REPO\",\"private\":true,\"auto_init\":true,\"default_branch\":\"main\"}")"
if [ "$repo_status" != "201" ]; then
  echo "Could not create the temporary repository."
  exit 1
fi
CREATED_REPO=1

echo "OK: temporary Gitea organization and repository created."

echo
echo "Step 5: clone, commit, and push."
mkdir -p "$WORK_DIR/$TEMP_ORG"
REPO_URL="$GITEA_BASE_URL/$TEMP_ORG/$TEMP_REPO.git"

ASKPASS_FILE="$(mktemp)"
cat > "$ASKPASS_FILE" <<'EOF'
#!/usr/bin/env bash
case "$1" in
  *Username*) printf '%s\n' "$TEMP_USER" ;;
  *Password*) printf '%s\n' "$TEMP_PASS" ;;
  *) printf '\n' ;;
esac
EOF
chmod 700 "$ASKPASS_FILE"

export TEMP_USER
export TEMP_PASS
export GIT_ASKPASS="$ASKPASS_FILE"
export GIT_TERMINAL_PROMPT=0

if ! git clone "$REPO_URL" "$TARGET_DIR"; then
  echo "Clone failed."
  exit 1
fi

cd "$TARGET_DIR"
git config user.name "Ektisis Smoke Test"
git config user.email "ektisis-smoke-test@example.local"

{
  echo "Ektisis Phase 1B automated smoke test"
  echo "Generated at: $(date '+%Y-%m-%d %H:%M:%S %z')"
} > "$TEST_FILE"

git add "$TEST_FILE"
git commit -m "test: validate automated Phase 1B Git flow"

if ! git push; then
  echo "Push failed."
  exit 1
fi

echo
echo "Phase 1B automated smoke test passed."
echo
echo "Validated:"
echo "- temporary Gitea user creation"
echo "- temporary organization creation"
echo "- temporary repository creation"
echo "- Git clone"
echo "- Git commit"
echo "- Git push"
echo "- automatic cleanup"
