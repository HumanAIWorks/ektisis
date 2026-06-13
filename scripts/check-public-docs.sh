#!/usr/bin/env bash
set -euo pipefail

FAIL=0

echo "== Ektisis public documentation exposure check =="
echo

check_pattern() {
  local label="$1"
  local pattern="$2"
  local result

  result="$(grep -RInE "$pattern" \
    --exclude-dir=.git \
    --exclude='check-public-docs.sh' \
    . || true)"

  if [ -n "$result" ]; then
    echo "FAIL: $label"
    echo "$result"
    echo
    FAIL=$((FAIL + 1))
  else
    echo "OK: $label"
  fi
}

# Environment-specific values that must never appear in public docs or scripts.
check_pattern "known real public IP fragments" '137\.131\.|177\.76\.'
check_pattern "known real local IP" '192\.168\.15\.12'
check_pattern "known personal/local hostnames" 'fabrica-local|ektisis-vnic'
check_pattern "known local usernames" '(^|[^A-Za-z0-9_-])(mario|ubuntu)([^A-Za-z0-9_-]|$)'

# IPv4 literals are allowed only for explicit placeholders and infrastructure constants.
IP_RESULTS="$(grep -RInE '([0-9]{1,3}\.){3}[0-9]{1,3}' \
  --exclude-dir=.git \
  --exclude='check-public-docs.sh' \
  . \
  | grep -vE '0\.0\.0\.0|127\.0\.0\.1|169\.254\.169\.254|203\.0\.113\.[0-9]+' || true)"

if [ -n "$IP_RESULTS" ]; then
  echo "FAIL: unexpected IPv4 literal found"
  echo "$IP_RESULTS"
  echo
  FAIL=$((FAIL + 1))
else
  echo "OK: no unexpected IPv4 literals"
fi

# Common secret-looking assignments should not be committed with real values.
SECRET_RESULTS="$(grep -RInE '(PASSWORD|TOKEN|SECRET|PRIVATE_KEY)=' \
  --exclude-dir=.git \
  --exclude='check-public-docs.sh' \
  --exclude='bootstrap.sh' \
  . || true)"

if [ -n "$SECRET_RESULTS" ]; then
  echo "FAIL: committed secret-looking assignment found"
  echo "$SECRET_RESULTS"
  echo
  FAIL=$((FAIL + 1))
else
  echo "OK: no committed secret-looking assignments"
fi

echo
if [ "$FAIL" -eq 0 ]; then
  echo "Public documentation exposure check passed."
  exit 0
fi

echo "Public documentation exposure check failed."
exit 1
