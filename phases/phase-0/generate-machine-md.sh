#!/usr/bin/env bash
set -euo pipefail

RUNTIME_DIR="${EKTISIS_RUNTIME_DIR:-$HOME/ektisis-runtime}"
OUT="${1:-$RUNTIME_DIR/MACHINE.md}"
mkdir -p "$(dirname "$OUT")"

HOSTNAME_VALUE="$(hostname 2>/dev/null || echo 'not detected')"
USER_VALUE="$(whoami 2>/dev/null || echo 'not detected')"
DATE_VALUE="$(date '+%Y-%m-%d %H:%M:%S %z')"
OS_VALUE="$(. /etc/os-release 2>/dev/null && echo "${PRETTY_NAME:-not detected}" || echo 'not detected')"
IP_VALUE="$(hostname -I 2>/dev/null | xargs || echo 'not detected')"
CPU_VALUE="$(lscpu 2>/dev/null | awk -F: '/Model name/ {gsub(/^[ \t]+/, "", $2); print $2; exit}' || echo 'not detected')"
RAM_VALUE="$(free -h 2>/dev/null | awk '/Mem:/ {print $2}' || echo 'not detected')"
DOCKER_VALUE="$(docker --version 2>/dev/null || echo 'not installed or no permission')"
COMPOSE_VALUE="$(docker compose version 2>/dev/null || echo 'not installed or no permission')"
DOCKER_ROOT="$(docker info 2>/dev/null | awk -F: '/Docker Root Dir/ {gsub(/^[ \t]+/, "", $2); print $2; exit}' || echo 'not detected')"
SSH_STATUS="$(systemctl is-active ssh 2>/dev/null || systemctl is-active sshd 2>/dev/null || echo 'not detected')"

cat > "$OUT" << EOM
# Ektisis Machine Inventory

Generated at: $DATE_VALUE

## Identity

Hostname: $HOSTNAME_VALUE
User: $USER_VALUE
Operating system: $OS_VALUE
IPs: $IP_VALUE

## Runtime

Runtime directory: $RUNTIME_DIR

## Hardware

CPU: $CPU_VALUE
RAM: $RAM_VALUE

## Docker

Docker: $DOCKER_VALUE
Docker Compose: $COMPOSE_VALUE
Docker Root Dir: $DOCKER_ROOT

## SSH

SSH service: $SSH_STATUS

## Disk

\`\`\`txt
$(df -h / /var /home 2>/dev/null || df -h /)
\`\`\`

EOM

echo "Machine inventory generated at: $OUT"
