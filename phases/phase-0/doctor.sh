#!/usr/bin/env bash
set -u

echo "== Ektisis Phase 0 Doctor =="

FAIL=0
WARN=0
PASS=0

ok() { echo "OK: $1"; PASS=$((PASS+1)); }
warn() { echo "WARN: $1"; WARN=$((WARN+1)); }
fail() { echo "FAIL: $1"; FAIL=$((FAIL+1)); }

if [ -f /etc/os-release ]; then
  . /etc/os-release
  echo "OS: ${PRETTY_NAME:-unknown}"
  case "${ID:-unknown}" in
    debian|ubuntu) ok "supported OS" ;;
    *) fail "unsupported OS: ${ID:-unknown}" ;;
  esac
else
  fail "missing /etc/os-release"
fi

hostname >/dev/null 2>&1 && ok "hostname available" || fail "hostname unavailable"
hostname -I >/dev/null 2>&1 && ok "IP command available" || warn "IP command unavailable"

systemctl is-active ssh >/dev/null 2>&1 || systemctl is-active sshd >/dev/null 2>&1 \
  && ok "SSH active" || warn "SSH not active"

if command -v docker >/dev/null 2>&1; then
  ok "docker command found"
  docker ps >/dev/null 2>&1 && ok "docker works without sudo" || warn "docker may require sudo or group membership"
else
  warn "docker not installed"
fi

if docker compose version >/dev/null 2>&1; then
  ok "docker compose works"
else
  warn "docker compose not available"
fi

df -h / /var /home 2>/dev/null || df -h /

echo "PASS: $PASS"
echo "WARN: $WARN"
echo "FAIL: $FAIL"

[ "$FAIL" -eq 0 ]
