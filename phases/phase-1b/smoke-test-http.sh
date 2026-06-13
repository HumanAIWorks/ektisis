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
SAFE_REPO_URL="${GITEA_BASE_URL}/${GITEA_ORG}/${GITEA_REPO}.git"
AUTH_REPO_URL="${GITEA_BASE_URL#http://}"
AUTH_REPO_URL="http://${GITEA_USERNAME}:${GITEA_PASSWORD}@${AUTH_REPO_URL}/${GITEA_ORG}/${GITEA_REPO}.git"

TARGET_DIR="${WORK_DIR}/${GITEA_REPO}"
rm -rf "$TARGET_DIR"

echo
echo "Cloning: $SAFE_REPO_URL"
if ! git clone "$AUTH_REPO_URL" "$TARGET_DIR"; then
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
TEST_FILE="phase-1b-smoke-test.txt"
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
echo "Open this repository in the browser and confirm the file exists:"
echo
echo "${GITEA_BASE_URL}/${GITEA_ORG}/${GITEA_REPO}"
