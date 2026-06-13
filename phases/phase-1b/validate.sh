#!/usr/bin/env bash
set -euo pipefail

PASS=0
FAIL=0

ok() {
  echo "OK: $1"
  PASS=$((PASS + 1))
}

fail() {
  echo "FAIL: $1"
  FAIL=$((FAIL + 1))
}

echo "== Ektisis Phase 1B Validation =="
echo

if [ -d "$HOME/ektisis-runtime" ]; then
  ok "runtime directory exists"
else
  fail "runtime directory missing: $HOME/ektisis-runtime"
fi

if [ -f "$HOME/ektisis-runtime/compose/phase-1a/.env" ]; then
  ok "Phase 1A environment file exists"
  # shellcheck disable=SC1091
  source "$HOME/ektisis-runtime/compose/phase-1a/.env"
else
  fail "Phase 1A environment file missing"
fi

if command -v git >/dev/null 2>&1; then
  ok "git command found"
else
  fail "git command not found"
fi

if docker ps >/dev/null 2>&1; then
  ok "Docker command works for the current user"
else
  fail "Docker command does not work for the current user"
fi

if docker ps --format '{{.Names}}' | grep -qx 'ektisis-gitea'; then
  ok "Gitea container is running"
else
  fail "Gitea container is not running"
fi

if docker ps --format '{{.Names}}' | grep -qx 'ektisis-postgres'; then
  ok "PostgreSQL container is running"
else
  fail "PostgreSQL container is not running"
fi

HTTP_PORT="${GITEA_HTTP_PORT:-3000}"
if curl -fsS "http://127.0.0.1:${HTTP_PORT}/" >/dev/null 2>&1; then
  ok "Gitea responds locally on port ${HTTP_PORT}"
else
  fail "Gitea does not respond locally on port ${HTTP_PORT}"
fi

TEST_DIR="$HOME/ektisis-runtime/projects/phase-1b-auto-smoke"
mkdir -p "$TEST_DIR"
if [ -d "$TEST_DIR" ]; then
  ok "automated smoke test workspace exists: $TEST_DIR"
else
  fail "could not create automated smoke test workspace"
fi

echo
echo "PASS: $PASS"
echo "FAIL: $FAIL"
echo

if [ "$FAIL" -eq 0 ]; then
  echo "Phase 1B validation passed. Ready for the automated Gitea smoke test."
  echo
  echo "Run next:"
  echo
  echo "bash phases/phase-1b/run.sh"
  exit 0
fi

echo "Phase 1B validation failed."
echo
echo "Start by checking Phase 1A:"
echo
echo "bash phases/phase-1a/validate.sh"
echo "bash phases/phase-1a/check-access.sh"
exit 1
