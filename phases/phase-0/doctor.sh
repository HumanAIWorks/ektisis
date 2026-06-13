#!/usr/bin/env bash
set -u

echo "== Ektisis Phase 0 Doctor =="

FAIL=0
WARN=0
PASS=0
NOTES=()

ok() { echo "OK: $1"; PASS=$((PASS+1)); }
warn() { echo "WARN: $1"; WARN=$((WARN+1)); NOTES+=("$2"); }
fail() { echo "FAIL: $1"; FAIL=$((FAIL+1)); NOTES+=("$2"); }

print_command() {
  echo
  echo "$1"
  echo
  echo "$2"
}

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
  && ok "SSH active" || warn "SSH not active" "The baseline step installs and enables OpenSSH."

if command -v docker >/dev/null 2>&1; then
  ok "docker command found"
  if docker ps >/dev/null 2>&1; then
    ok "docker works without sudo"
  else
    warn "docker may require sudo or group membership" "The baseline step configures Docker group access. If Docker was just installed, reconnect or run: newgrp docker."
  fi
else
  warn "docker not installed" "The baseline step installs Docker."
fi

if docker compose version >/dev/null 2>&1; then
  ok "docker compose works"
else
  warn "docker compose not available" "The baseline step installs the Docker Compose plugin."
fi

df -h / /var /home 2>/dev/null || df -h /

echo
echo "PASS: $PASS"
echo "WARN: $WARN"
echo "FAIL: $FAIL"

echo
if [ "$FAIL" -gt 0 ]; then
  echo "Result: BLOCKED"
  echo "Fix the FAIL items before continuing."
elif [ "$WARN" -gt 0 ]; then
  echo "Result: NEEDS BASELINE"
  echo "Warnings are expected on a fresh machine. Continue with the baseline step."
else
  echo "Result: READY TO VALIDATE"
  echo "This machine already looks prepared. Run validation next."
fi

# Print unique notes while preserving order.
if [ "${#NOTES[@]}" -gt 0 ]; then
  echo
  echo "Notes:"
  seen=""
  for note in "${NOTES[@]}"; do
    case "$seen" in
      *"|$note|"*) ;;
      *)
        echo "- $note"
        seen="$seen|$note|"
        ;;
    esac
  done
fi

if [ "$FAIL" -eq 0 ] && [ "$WARN" -gt 0 ]; then
  print_command "Run next:" "sudo bash phases/phase-0/bootstrap.sh"
elif [ "$FAIL" -eq 0 ]; then
  print_command "Run next:" "bash phases/phase-0/validate.sh"
fi

[ "$FAIL" -eq 0 ]