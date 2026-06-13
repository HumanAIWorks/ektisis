#!/usr/bin/env bash
set -u

FAIL=0

pass() { echo "OK: $1"; }
fail() { echo "FAIL: $1"; FAIL=$((FAIL+1)); }

check() {
  local label="$1"
  local cmd="$2"
  if bash -c "$cmd" >/dev/null 2>&1; then
    pass "$label"
  else
    fail "$label"
  fi
}

echo "== Ektisis Phase 0 Validation =="

check "OS metadata exists" "test -f /etc/os-release"

if [ -f /etc/os-release ]; then
  . /etc/os-release
  case "${ID:-unknown}" in
    debian|ubuntu) pass "supported OS: ${ID}" ;;
    *) fail "unsupported OS: ${ID:-unknown}" ;;
  esac
fi

check "hostname available" "hostname"
check "IP available" "hostname -I | grep -q '[0-9]'"
check "SSH active" "systemctl is-active ssh | grep -q active || systemctl is-active sshd | grep -q active"
check "Docker active" "systemctl is-active docker | grep -q active"
check "Docker command works" "docker ps"
check "Docker Compose works" "docker compose version"

DOCKER_ROOT="$(docker info 2>/dev/null | awk -F: '/Docker Root Dir/ {gsub(/^[ \t]+/, "", $2); print $2; exit}' || true)"
if [ -n "$DOCKER_ROOT" ]; then
  pass "Docker Root Dir detected: $DOCKER_ROOT"
else
  fail "Docker Root Dir not detected"
fi

VAR_AVAIL="$(df -BG /var 2>/dev/null | awk 'NR==2 {gsub("G","",$4); print $4}' || true)"
if [ -n "${VAR_AVAIL:-}" ] && [ "$VAR_AVAIL" -lt 30 ] && [ "$DOCKER_ROOT" = "/var/lib/docker" ]; then
  fail "/var is small and Docker still uses /var/lib/docker"
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
  check "UFW active" "sudo -n $UFW_BIN status | grep -q 'Status: active'"
  check "OpenSSH allowed in UFW" "sudo -n $UFW_BIN status | grep -q 'OpenSSH\|22/tcp'"
else
  fail "UFW command not found"
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
fi

for path in "$HOME/ektisis/data" "$HOME/ektisis/compose" "$HOME/ektisis/backups" "$HOME/ektisis/secrets" "$HOME/ektisis/logs" "$HOME/ektisis/projects"; do
  if [ -d "$path" ]; then
    pass "directory exists: $path"
  else
    fail "missing directory: $path"
  fi
done

if [ "$FAIL" -eq 0 ]; then
  echo "Phase 0 validated. Machine is ready for Phase 1A."
  exit 0
else
  echo "Phase 0 validation failed with $FAIL issue(s)."
  exit 1
fi
