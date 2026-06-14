#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

echo "== Ektisis Phase 1 — Gitea =="
echo
echo "This phase installs and validates the Gitea Git server stack."
echo

echo "Step 1: validate Phase 0 machine baseline."
if ! bash phases/phase-0/validate.sh; then
  echo
  echo "Phase 0 validation failed. Fix the machine baseline before running Phase 1."
  exit 1
fi

echo
echo "Step 2: start Gitea and PostgreSQL."
if ! bash phases/phase-1a/bootstrap.sh; then
  echo
  echo "Gitea bootstrap failed."
  exit 1
fi

echo
echo "Step 3: validate Gitea and PostgreSQL health."
if ! bash phases/phase-1a/validate.sh; then
  echo
  echo "Gitea service validation failed."
  exit 1
fi

echo
echo "Step 4: check Gitea access."
if ! bash phases/phase-1a/check-access.sh; then
  echo
  echo "Gitea access check failed."
  exit 1
fi

echo
echo "Step 5: validate Git operations with temporary resources."
if ! bash phases/phase-1b/run.sh; then
  echo
  echo "Gitea Git smoke test failed."
  exit 1
fi

echo
echo "Phase 1 completed: Gitea is installed and Git operations are validated."
echo
echo "Run next:"
echo
echo "bash phases/phase-2/run.sh"
