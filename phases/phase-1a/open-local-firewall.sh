#!/usr/bin/env bash
set -euo pipefail

RUNTIME_DIR="${EKTISIS_RUNTIME_DIR:-$HOME/ektisis-runtime}"
ENV_FILE="$RUNTIME_DIR/compose/phase-1a/.env"
HTTP_PORT="3000"
SSH_PORT="2222"

load_env_value() {
  local key="$1"
  if [ -f "$ENV_FILE" ]; then
    awk -F= -v k="$key" '$1 == k {print substr($0, length(k) + 2); exit}' "$ENV_FILE"
  fi
}

if [ -f "$ENV_FILE" ]; then
  HTTP_PORT="$(load_env_value GITEA_HTTP_PORT || true)"
  SSH_PORT="$(load_env_value GITEA_SSH_PORT || true)"
  [ -z "$HTTP_PORT" ] && HTTP_PORT="3000"
  [ -z "$SSH_PORT" ] && SSH_PORT="2222"
fi

if [ "$(id -u)" -ne 0 ]; then
  echo "This script changes the local firewall, so it needs sudo."
  echo
  echo "Run:"
  echo
  echo "sudo bash phases/phase-1a/open-local-firewall.sh"
  exit 1
fi

UFW_BIN="$(command -v ufw || echo /usr/sbin/ufw)"
if [ ! -x "$UFW_BIN" ]; then
  echo "UFW was not found. UFW is the simple firewall tool used by this project."
  exit 1
fi

"$UFW_BIN" allow "${HTTP_PORT}/tcp"
"$UFW_BIN" allow "${SSH_PORT}/tcp"
"$UFW_BIN" --force enable

echo
echo "Local firewall updated."
echo
echo "Allowed ports:"
echo "- $HTTP_PORT/tcp for Gitea web access"
echo "- $SSH_PORT/tcp for Gitea Git over SSH"
echo
echo "If the browser still cannot open Gitea on a VPS, check the provider firewall too."
