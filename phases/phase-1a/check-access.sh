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

LOCAL_IP="$(hostname -I 2>/dev/null | awk '{print $1}' || true)"
[ -z "$LOCAL_IP" ] && LOCAL_IP="not detected"

PUBLIC_EGRESS_IP="not detected"
if command -v curl >/dev/null 2>&1; then
  VALUE="$(curl -fsS --max-time 3 https://api.ipify.org 2>/dev/null || true)"
  [ -n "$VALUE" ] && PUBLIC_EGRESS_IP="$VALUE"
fi

CLOUD_HINT="unknown"
if curl -fsS --max-time 1 http://169.254.169.254/opc/v2/instance/ >/dev/null 2>&1; then
  CLOUD_HINT="Oracle Cloud Infrastructure likely"
elif curl -fsS --max-time 1 http://169.254.169.254/latest/meta-data/ >/dev/null 2>&1; then
  CLOUD_HINT="AWS or AWS-compatible VPS likely"
elif curl -fsS --max-time 1 -H Metadata:true 'http://169.254.169.254/metadata/instance?api-version=2021-02-01' >/dev/null 2>&1; then
  CLOUD_HINT="Azure likely"
elif printf '%s' "$LOCAL_IP" | grep -qE '^(192\.168\.|10\.|172\.(1[6-9]|2[0-9]|3[0-1])\.)'; then
  CLOUD_HINT="local network or private network likely"
fi

echo "== Ektisis Phase 1A Access Check =="
echo
echo "This check helps explain why Gitea may open on the server but not in your browser."
echo
echo "Detected information:"
echo "- Local IP: $LOCAL_IP"
echo "- Public egress IP: $PUBLIC_EGRESS_IP"
echo "- Gitea HTTP port: $HTTP_PORT"
echo "- Gitea SSH port: $SSH_PORT"
echo "- Environment hint: $CLOUD_HINT"
echo

LOCAL_OK=0
if curl -fsS --max-time 5 "http://127.0.0.1:$HTTP_PORT/" >/dev/null 2>&1; then
  echo "OK: Gitea responds inside this machine."
  LOCAL_OK=1
else
  echo "FAIL: Gitea does not respond inside this machine."
  echo
  echo "Run validation first:"
  echo
  echo "bash phases/phase-1a/validate.sh"
  exit 1
fi

LISTEN_INFO="$(ss -ltn 2>/dev/null | grep ":$HTTP_PORT " || true)"
if [ -n "$LISTEN_INFO" ]; then
  echo "OK: Port $HTTP_PORT is listening on this machine."
else
  echo "WARN: Port $HTTP_PORT was not found in the listening port list."
fi

UFW_STATUS="$(sudo -n ufw status 2>/dev/null || ufw status 2>/dev/null || true)"
if printf '%s' "$UFW_STATUS" | grep -qi 'Status: active'; then
  if printf '%s' "$UFW_STATUS" | grep -qE "(^| )$HTTP_PORT/tcp|$HTTP_PORT"; then
    echo "OK: Local firewall appears to allow port $HTTP_PORT."
  else
    echo "WARN: Local firewall is active and port $HTTP_PORT is not clearly allowed."
    echo
    echo "To open the local firewall, run:"
    echo
    echo "sudo bash phases/phase-1a/open-local-firewall.sh"
  fi
else
  echo "OK: Local firewall is not active or could not be checked."
fi

echo
if [ "$PUBLIC_EGRESS_IP" != "not detected" ]; then
  echo "Try this URL from your browser:"
  echo
  echo "http://$PUBLIC_EGRESS_IP:$HTTP_PORT/"
else
  echo "Public browser URL could not be detected automatically."
fi

echo
cat << EOF_HELP
If Gitea works locally but does not open in your browser, the most common cause is an external firewall.

A firewall is a rule system that decides which network connections are allowed.
A port is a numbered door used by a service; here, Gitea uses port $HTTP_PORT for the web page.

Recommended next documentation:
EOF_HELP

case "$CLOUD_HINT" in
  *Oracle*)
    echo
    echo "docs/troubleshooting/oci.md"
    ;;
  *local*)
    echo
    echo "docs/troubleshooting/local-network.md"
    ;;
  *)
    echo
    echo "docs/troubleshooting/generic-vps.md"
    ;;
esac
