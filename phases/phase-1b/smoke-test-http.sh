#!/usr/bin/env bash
set -euo pipefail

ENV_FILE="$HOME/ektisis-runtime/compose/phase-1a/.env"
WORK_DIR="$HOME/ektisis-runtime/projects/phase-1b-smoke-test"

if [ ! -f "$ENV_FILE" ]; then
  echo "Phase 1A environment file was not found."
  echo
  echo "Run first:"
  echo
  echo "bash phases/phase-1a/validate.sh"
  exit 1
fi

# shellcheck disable=SC1091
source "$ENV_FILE"

GITEA_BASE_URL="${GITEA_ROOT_URL:-http://127.0.0.1:3000/}"
GITEA_BASE_URL="${GITEA_BASE_URL%/}"

mkdir -p "$WORK_DIR"
cd "$WORK_DIR"

echo "== Ektisis Phase 1B Git Smoke Test =="
echo
echo "This test clones a Gitea repository, creates a small file, commits it, and pushes it back."
echo

default_org="ektisis"
default_repo="phase-1b-smoke-test"

read -r -p "Gitea username: " GITEA_USERNAME
read -r -s -p "Gitea password or token: " GITEA_PASSWORD
echo
read -r -p "Organization [${default_org}]: " GITEA_ORG
GITEA_ORG="${GITEA_ORG:-$default_org}"
read -r -p "Repository [${default_repo}]: " GITEA_REPO
GITEA_REPO="${GITEA_REPO:-$default_repo}"

if [ -z "$GITEA_USERNAME" ] || [ -z "$GITEA_PASSWORD" ]; then
  echo
  echo "Username and password/token are required."
  exit 1
fi

REPO_URL="${GITEA_BASE_URL}/${GITEA_ORG}/${GITEA_REPO}.git"
REPO_BROWSER_URL="${GITEA_BASE_URL}/${GITEA_ORG}/${GITEA_REPO}"
TARGET_DIR="${WORK_DIR}/${GITEA_REPO}"
TEST_FILE="phase-1b-smoke-test.txt"
rm -rf "$TARGET_DIR"

ASKPASS_FILE="$(mktemp)"
cleanup() {
  rm -f "$ASKPASS_FILE"
}
trap cleanup EXIT

cat > "$ASKPASS_FILE" <<'EOF'
#!/usr/bin/env bash
case "$1" in
  *Username*) printf '%s\n' "$GITEA_USERNAME" ;;
  *Password*) printf '%s\n' "$GITEA_PASSWORD" ;;
  *) printf '\n' ;;
esac
EOF
chmod 700 "$ASKPASS_FILE"

export GITEA_USERNAME
export GITEA_PASSWORD
export GIT_ASKPASS="$ASKPASS_FILE"
export GIT_TERMINAL_PROMPT=0

echo
echo "Cloning: $REPO_URL"
if ! git clone "$REPO_URL" "$TARGET_DIR"; then
  echo
  echo "Clone failed."
  echo
  echo "Check in the browser:"
  echo "- the organization exists"
  echo "- the repository exists"
  echo "- the repository was initialized with a README"
  echo "- the username and password/token are correct"
  exit 1
fi

cd "$TARGET_DIR"

git config user.name "Ektisis Smoke Test"
git config user.email "ektisis-smoke-test@example.local"

STAMP="$(date '+%Y-%m-%d %H:%M:%S %z')"
{
  echo "Ektisis Phase 1B smoke test"
  echo "Generated at: $STAMP"
} > "$TEST_FILE"

git add "$TEST_FILE"

if git diff --cached --quiet; then
  echo "No changes to commit."
else
  git commit -m "test: validate Phase 1B Git push"
fi

echo
echo "Pushing test commit..."
if ! git push; then
  echo
  echo "Push failed."
  echo
  echo "Check that your Gitea user has write access to the repository."
  exit 1
fi

echo
echo "Phase 1B smoke test completed."
echo
echo "Open this repository in the browser:"
echo
echo "$REPO_BROWSER_URL"
echo
echo "Confirm that this file appears in the repository file list:"
echo
echo "$TEST_FILE"
echo
echo "If the file does not appear yet, refresh the browser page."
echo "The script pushed the commit, but the browser UI does not refresh automatically."
