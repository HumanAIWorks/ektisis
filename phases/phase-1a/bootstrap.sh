#!/usr/bin/env bash
set -euo pipefail

RUNTIME_DIR="${EKTISIS_RUNTIME_DIR:-$HOME/ektisis-runtime}"
PHASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMPOSE_FILE="$PHASE_DIR/compose.yml"
ENV_DIR="$RUNTIME_DIR/compose/phase-1a"
ENV_FILE="$ENV_DIR/.env"

if [ "$(id -u)" -eq 0 ]; then
  echo "Do not run this script as root."
  echo
  echo "Run:"
  echo
  echo "bash phases/phase-1a/bootstrap.sh"
  exit 1
fi

if ! docker ps >/dev/null 2>&1; then
  echo "Docker is not available without sudo. Run Phase 0 validation first."
  echo
  echo "bash phases/phase-0/validate.sh"
  exit 1
fi

if ! docker compose version >/dev/null 2>&1; then
  echo "Docker Compose is not available. Run Phase 0 validation first."
  echo
  echo "bash phases/phase-0/validate.sh"
  exit 1
fi

mkdir -p "$ENV_DIR"
mkdir -p "$RUNTIME_DIR/data/postgres"
mkdir -p "$RUNTIME_DIR/data/gitea"
mkdir -p "$RUNTIME_DIR/logs/phase-1a"

LOCAL_IP="$(hostname -I 2>/dev/null | awk '{print $1}' || true)"
if [ -z "$LOCAL_IP" ]; then
  LOCAL_IP="localhost"
fi

PUBLIC_EGRESS_IP=""
if command -v curl >/dev/null 2>&1; then
  PUBLIC_EGRESS_IP="$(curl -fsS --max-time 3 https://api.ipify.org 2>/dev/null || true)"
fi

GITEA_DOMAIN_DEFAULT="$LOCAL_IP"
if [ -n "$PUBLIC_EGRESS_IP" ]; then
  GITEA_DOMAIN_DEFAULT="$PUBLIC_EGRESS_IP"
fi

if [ ! -f "$ENV_FILE" ]; then
  if command -v openssl >/dev/null 2>&1; then
    POSTGRES_PASSWORD_VALUE="$(openssl rand -hex 24)"
  else
    POSTGRES_PASSWORD_VALUE="$(date +%s%N | sha256sum | awk '{print $1}')"
  fi

  cat > "$ENV_FILE" << EOF_ENV
EKTISIS_RUNTIME_DIR=$RUNTIME_DIR
POSTGRES_IMAGE=postgres:16-alpine
POSTGRES_DB=gitea
POSTGRES_USER=gitea
POSTGRES_PASSWORD=$POSTGRES_PASSWORD_VALUE
GITEA_IMAGE=gitea/gitea:latest
GITEA_HTTP_PORT=3000
GITEA_SSH_PORT=2222
GITEA_DOMAIN=$GITEA_DOMAIN_DEFAULT
GITEA_SSH_DOMAIN=$GITEA_DOMAIN_DEFAULT
GITEA_ROOT_URL=http://$GITEA_DOMAIN_DEFAULT:3000/
GITEA_USER_UID=$(id -u)
GITEA_USER_GID=$(id -g)
EOF_ENV

  chmod 600 "$ENV_FILE"
  echo "Created Phase 1A environment file: $ENV_FILE"
else
  echo "Using existing Phase 1A environment file: $ENV_FILE"
fi

docker compose --env-file "$ENV_FILE" -f "$COMPOSE_FILE" -p ektisis-phase-1a up -d

echo
echo "Phase 1A bootstrap completed."
echo
echo "Run validation:"
echo
echo "bash phases/phase-1a/validate.sh"
