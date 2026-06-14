#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

echo "== Ektisis Phase 1A Run =="
echo
echo "This script runs the official Phase 1A flow."
echo

echo "Step 1: bootstrap Gitea and PostgreSQL."
if ! bash phases/phase-1a/bootstrap.sh; then
  echo
  echo "Phase 1A bootstrap failed."
  echo "Read: phases/phase-1a/README.md"
  exit 1
fi

echo
echo "Step 2: validate Gitea and PostgreSQL."
if ! bash phases/phase-1a/validate.sh; then
  echo
  echo "Phase 1A validation failed."
  echo "Read: phases/phase-1a/README.md"
  exit 1
fi

echo
echo "Step 3: check Gitea access."
if ! bash phases/phase-1a/check-access.sh; then
  echo
  echo "Phase 1A access check failed."
  echo "Follow the troubleshooting document suggested by the access check."
  exit 1
fi

echo
echo "Phase 1A completed."
echo
echo "Run next:"
echo
echo "bash phases/phase-1b/run.sh"
