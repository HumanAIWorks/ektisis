#!/usr/bin/env bash
set -u

FAIL=0
NEXT_ACTIONS=()
RUNTIME_DIR="${EKTISIS_RUNTIME_DIR:-$HOME/ektisis-runtime}"

pass() { echo "OK: $1"; }
fail() { echo "FAIL: $1"; FAIL=$((FAIL+1)); }
next_action() { NEXT_ACTIONS+=("$1"); }

check() {
  local label="$1"
  local cmd="$2"
  local action="${3:-}"
  if bash -c "$cmd" >/dev/null 2>&1; then
    pass "$label"
  else
    fail "$label"
    if [ -n "$action" ]; then
      next_action "$action"
    fi
  fi
}

echo "== Ektisis Phase 0 Validation =="
echo "Runtime directory: $RUNTIME_DIR"

check "OS metadata exists" "test -f /etc/os-release" "Use Debian 12+ or Ubuntu Server LTS."

if [ -f /etc/os-release ]; then
  . /etc/os-release
  case "${ID:-unknown}" in
    debian|ubuntu) pass "supported OS: ${ID}" ;;
    *) fail "unsupported OS: ${ID:-unknown}"; next_action "Use Debian 12+ or Ubuntu Server LTS." ;;
  esac
fi

check "hostname available" "hostname" "Configure a hostname with hostnamectl."
check "IP available" "hostname -I | grep -q '[0-9]'" "Check network connectivity before continuing."
check "SSH active" "systemctl is-active ssh | grep -q active || systemctl is-active sshd | grep -q active" "Run: sudo bash phases/phase-0/bootstrap.sh"
check "Docker active" "systemctl is-active docker | grep -q active" "Run: sudo bash phases/phase-0/bootstrap.sh"

if docker ps >/dev/null 2>&1; then
  pass "Docker command works without sudo"
else
  fail "Docker command does not work without sudo"
  if groups | grep -qw docker; then
    next_action "Your user is in the docker group but this session may be stale. Run: exit ; ssh your_user@SERVER_IP ; cd ektisis ; bash phases/phase-0/validate.sh"
  else
    next_action "Run: sudo bash phases/phase-0/bootstrap.sh. Then reconnect or run: newgrp docker"
  fi
fi

check "Docker Compose works" "docker compose version" "Run: sudo bash phases/phase-0/bootstrap.sh"

DOCKER_ROOT="$(docker info 2>/dev/null | awk -F: '/Docker Root Dir/ {gsub(/^[ \t]+/, "", $2); print $2; exit}' || true)"
if [ -n "$DOCKER_ROOT" ]; then
  pass "Docker Root Dir detected: $DOCKER_ROOT"
else
  fail "Docker Root Dir not detected"
  next_action "Run: sudo bash phases/phase-0/bootstrap.sh"
fi

VAR_AVAIL="$(df -BG /var 2>/dev/null | awk 'NR==2 {gsub("G","",$4); print $4}' || true)"
if [ -n "${VAR_AVAIL:-}" ] && [ "$VAR_AVAIL" -lt 30 ] && [ "$DOCKER_ROOT" = "/var/lib/docker" ]; then
  fail "/var is small and Docker still uses /var/lib/docker"
  next_action "Run bootstrap before creating containers, or set EKTISIS_DOCKER_DATA_ROOT to a larger disk."
else
  pass "Docker data-root is acceptable for current disk layout"
fi

if command -v ufw >/dev/null 2>&1; then
  UFW_BIN="ufw"
elif [ -x /usr/sbin/ufw ]; then
  UFW_BIN="/usr/sbin/ufw"
else
  UFW_BIN=""
fi

if [ -n "$UFW_BIN" ]; then
  check "UFW active" "sudo -n $UFW_BIN status | grep -q 'Status: active'" "Run: sudo bash phases/phase-0/bootstrap.sh"
  check "OpenSSH allowed in UFW" "sudo -n $UFW_BIN status | grep -q 'OpenSSH\|22/tcp'" "Run: sudo bash phases/phase-0/bootstrap.sh"
else
  fail "UFW command not found"
  next_action "Run: sudo bash phases/phase-0/bootstrap.sh"
fi

MASKED_COUNT=0
for target in sleep.target suspend.target hibernate.target hybrid-sleep.target; do
  if systemctl is-enabled "$target" 2>/dev/null | grep -q masked; then
    MASKED_COUNT=$((MASKED_COUNT+1))
  fi
done

if [ "$MASKED_COUNT" -eq 4 ]; then
  pass "sleep/suspend/hibernate targets masked"
else
  fail "sleep/suspend/hibernate targets are not fully masked"
  next_action "Run: sudo bash phases/phase-0/bootstrap.sh"
fi

for path in "$RUNTIME_DIR/data" "$RUNTIME_DIR/compose" "$RUNTIME_DIR/backups" "$RUNTIME_DIR/secrets" "$RUNTIME_DIR/logs" "$RUNTIME_DIR/projects"; do
  if [ -d "$path" ]; then
    pass "directory exists: $path"
  else
    fail "missing directory: $path"
    next_action "Run: sudo bash phases/phase-0/bootstrap.sh"
  fi
done

if [ "$FAIL" -eq 0 ]; then
  echo "Phase 0 validated. Machine is ready for Phase 1A."
  exit 0
fi

echo "Phase 0 validation failed with $FAIL issue(s)."

if [ "${#NEXT_ACTIONS[@]}" -gt 0 ]; then
  echo
  echo "Next actions:"
  printf '%s\n' "${NEXT_ACTIONS[@]}" | awk '!seen[$0]++ {print "- " $0}'
fi

exit 1
