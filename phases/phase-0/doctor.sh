#!/usr/bin/env bash
set -u

echo "== Ektisis Phase 0 Doctor =="

FAIL=0
WARN=0
PASS=0
ACTIONS=()

ok() { echo "OK: $1"; PASS=$((PASS+1)); }
warn() { echo "WARN: $1"; WARN=$((WARN+1)); ACTIONS+=("$2"); }
fail() { echo "FAIL: $1"; FAIL=$((FAIL+1)); ACTIONS+=("$2"); }
add_action() { ACTIONS+=("$1"); }

if [ -f /etc/os-release ]; then
  . /etc/os-release
  echo "OS: ${PRETTY_NAME:-unknown}"
  case "${ID:-unknown}" in
    debian|ubuntu) ok "supported OS" ;;
    *) fail "unsupported OS: ${ID:-unknown}" "Use Debian 12+ minimal/server or Ubuntu Server LTS before continuing." ;;
  esac
else
  fail "missing /etc/os-release" "Run this only on a supported Debian or Ubuntu machine."
fi

hostname >/dev/null 2>&1 && ok "hostname available" || fail "hostname unavailable" "Set a hostname before continuing. Example: sudo hostnamectl set-hostname ektisis-node"
hostname -I >/dev/null 2>&1 && ok "IP command available" || warn "IP command unavailable" "Check network configuration. The machine must be reachable over the network before Phase 1A."

systemctl is-active ssh >/dev/null 2>&1 || systemctl is-active sshd >/dev/null 2>&1 \
  && ok "SSH active" || warn "SSH not active" "Run: sudo bash phases/phase-0/bootstrap.sh. It installs/enables OpenSSH."

if command -v docker >/dev/null 2>&1; then
  ok "docker command found"
  if docker ps >/dev/null 2>&1; then
    ok "docker works without sudo"
  else
    warn "docker may require sudo or group membership" "Run: sudo bash phases/phase-0/bootstrap.sh. If Docker was just installed, reconnect or run: newgrp docker."
  fi
else
  warn "docker not installed" "Run: sudo bash phases/phase-0/bootstrap.sh. It installs Docker from the official Docker APT repository."
fi

if docker compose version >/dev/null 2>&1; then
  ok "docker compose works"
else
  warn "docker compose not available" "Run: sudo bash phases/phase-0/bootstrap.sh. It installs the Docker Compose plugin."
fi

df -h / /var /home 2>/dev/null || df -h /

echo
echo "PASS: $PASS"
echo "WARN: $WARN"
echo "FAIL: $FAIL"

echo
if [ "$FAIL" -gt 0 ]; then
  echo "Result: BLOCKED"
  echo "Do not continue to bootstrap until the FAIL items are fixed."
elif [ "$WARN" -gt 0 ]; then
  echo "Result: NEEDS BASELINE"
  echo "Warnings are expected on a fresh machine. Continue with the baseline step."
else
  echo "Result: READY TO VALIDATE"
  echo "This machine already looks prepared. Run validation next."
fi

# Print unique next actions while preserving order.
if [ "${#ACTIONS[@]}" -gt 0 ]; then
  echo
  echo "Next actions:"
  seen=""
  for action in "${ACTIONS[@]}"; do
    case "$seen" in
      *"|$action|"*) ;;
      *)
        echo "- $action"
        seen="$seen|$action|"
        ;;
    esac
  done
fi

echo
if [ "$FAIL" -eq 0 ] && [ "$WARN" -gt 0 ]; then
  echo "Run next: sudo bash phases/phase-0/bootstrap.sh"
elif [ "$FAIL" -eq 0 ]; then
  echo "Run next: bash phases/phase-0/validate.sh"
fi

[ "$FAIL" -eq 0 ]