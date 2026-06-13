#!/usr/bin/env bash
set -euo pipefail

DOCKER_DATA_ROOT="${EKTISIS_DOCKER_DATA_ROOT:-/home/docker-data}"
INSTALL_DOCKER="${EKTISIS_INSTALL_DOCKER:-1}"
EKTISIS_HOME_NAME="${EKTISIS_HOME_NAME:-ektisis}"

if [ "$(id -u)" -ne 0 ]; then
  echo "Run as root, for example: sudo $0"
  exit 1
fi

if [ ! -f /etc/os-release ]; then
  echo "Unsupported system: /etc/os-release not found"
  exit 1
fi

. /etc/os-release
OS_ID="${ID:-unknown}"
OS_CODENAME="${VERSION_CODENAME:-}"

case "$OS_ID" in
  debian|ubuntu) ;;
  *) echo "Unsupported OS: $OS_ID"; exit 1 ;;
esac

if [ -z "$OS_CODENAME" ]; then
  echo "Could not detect OS codename"
  exit 1
fi

apt-get update
apt-get install -y ca-certificates curl wget gnupg lsb-release sudo git openssh-server ufw jq nano htop btop tree unzip net-tools dnsutils lsof

systemctl enable ssh >/dev/null 2>&1 || systemctl enable sshd >/dev/null 2>&1 || true
systemctl start ssh >/dev/null 2>&1 || systemctl start sshd >/dev/null 2>&1 || true

UFW_BIN="$(command -v ufw || echo /usr/sbin/ufw)"
if [ -x "$UFW_BIN" ]; then
  "$UFW_BIN" allow OpenSSH
  "$UFW_BIN" --force enable
fi

systemctl mask sleep.target suspend.target hibernate.target hybrid-sleep.target >/dev/null 2>&1 || true

if [ "$INSTALL_DOCKER" = "1" ] && ! command -v docker >/dev/null 2>&1; then
  for pkg in docker.io docker-doc docker-compose podman-docker containerd runc; do
    apt-get remove -y "$pkg" >/dev/null 2>&1 || true
  done

  install -m 0755 -d /etc/apt/keyrings
  curl -fsSL "https://download.docker.com/linux/${OS_ID}/gpg" -o /etc/apt/keyrings/docker.asc
  chmod a+r /etc/apt/keyrings/docker.asc

  cat > /etc/apt/sources.list.d/docker.sources << EOF_DOCKER
Types: deb
URIs: https://download.docker.com/linux/${OS_ID}
Suites: ${OS_CODENAME}
Components: stable
Architectures: $(dpkg --print-architecture)
Signed-By: /etc/apt/keyrings/docker.asc
EOF_DOCKER

  apt-get update
  apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
  systemctl enable docker
  systemctl start docker
fi

if command -v docker >/dev/null 2>&1; then
  CURRENT_ROOT="$(docker info 2>/dev/null | awk -F: '/Docker Root Dir/ {gsub(/^[ \t]+/, "", $2); print $2; exit}' || true)"
  CONTAINERS_COUNT="$(docker ps -aq 2>/dev/null | wc -l | tr -d ' ')"

  if [ "$CURRENT_ROOT" != "$DOCKER_DATA_ROOT" ] && [ "$CONTAINERS_COUNT" = "0" ]; then
    mkdir -p "$DOCKER_DATA_ROOT"
    chown root:root "$DOCKER_DATA_ROOT"
    chmod 711 "$DOCKER_DATA_ROOT"
    mkdir -p /etc/docker

    systemctl stop docker.service >/dev/null 2>&1 || true
    systemctl stop docker.socket >/dev/null 2>&1 || true
    systemctl stop containerd.service >/dev/null 2>&1 || true

    cat > /etc/docker/daemon.json << EOF_DAEMON
{
  "data-root": "$DOCKER_DATA_ROOT"
}
EOF_DAEMON

    if [ -d /var/lib/docker ] && [ "$CURRENT_ROOT" = "/var/lib/docker" ]; then
      mv /var/lib/docker "/var/lib/docker.bak.$(date +%Y%m%d%H%M%S)"
    fi

    systemctl start containerd.service >/dev/null 2>&1 || true
    systemctl start docker.socket >/dev/null 2>&1 || true
    systemctl start docker.service
  fi
fi

TARGET_USER="${SUDO_USER:-}"
if [ -n "$TARGET_USER" ] && id "$TARGET_USER" >/dev/null 2>&1; then
  usermod -aG docker "$TARGET_USER" || true
  TARGET_HOME="$(getent passwd "$TARGET_USER" | cut -d: -f6)"
  mkdir -p "$TARGET_HOME/$EKTISIS_HOME_NAME"/{data,compose,backups,secrets,logs,projects}
  mkdir -p "$TARGET_HOME/$EKTISIS_HOME_NAME/data"/{gitea,postgres,litellm,openhands,freellmapi}
  mkdir -p "$TARGET_HOME/$EKTISIS_HOME_NAME/backups"/{gitea,postgres,configs}
  chmod 700 "$TARGET_HOME/$EKTISIS_HOME_NAME/secrets"
  chown -R "$TARGET_USER:$TARGET_USER" "$TARGET_HOME/$EKTISIS_HOME_NAME"
  echo "User '$TARGET_USER' added to docker group. Re-login may be required."
fi

echo "Phase 0 bootstrap completed."
