#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

echo "== Ektisis Phase 1 — Gitea Validation =="
echo

if ! bash phases/phase-1a/validate.sh; then
  echo
  echo "Phase 1 validation failed: Gitea or PostgreSQL is not healthy."
  exit 1
fi

echo
if ! bash phases/phase-1a/check-access.sh; then
  echo
  echo "Phase 1 validation failed: Gitea access check failed."
  exit 1
fi

echo
echo "Phase 1 validation passed."
