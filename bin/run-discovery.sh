#!/bin/bash
# A.TT.I.L.A. Discovery Runner
# Co-authored by Jetski

set -euo pipefail

# 1. Load environment variables
ENV_FILE="${2:-.env}"
if [ -f "$ENV_FILE" ]; then
  echo "[+] Loading environment from $ENV_FILE..."
  set -a
  source "$ENV_FILE"
  set +a
else
  echo "[!] WARNING: Environment file $ENV_FILE not found."
fi

if [ -z "${PROJECT_ID:-}" ]; then
  echo "[-] ERROR: PROJECT_ID is not set in .env"
  exit 1
fi

VERSION=$(cat VERSION)
PROMPT="${1:-}"

# 2. Resolve the correct host user's home directory (supporting sudo)
USER_HOME=$HOME
if [ -n "${SUDO_USER:-}" ]; then
  USER_HOME=$(getent passwd "$SUDO_USER" | cut -d: -f6)
  echo "[+] Running under sudo. Resolved host user home to: $USER_HOME"
fi

# 3. Detect if we have a TTY (interactive terminal)
DOCKER_FLAGS="--rm"
if [ -t 0 ] && [ -t 1 ]; then
  DOCKER_FLAGS="$DOCKER_FLAGS -it"
  echo "[+] TTY detected. Running in interactive mode."
else
  echo "[+] No TTY detected. Running in non-interactive mode."
fi

# Retrieve active account from host to pass to gcloud in container
ACTIVE_ACCOUNT=$(gcloud config get-value account 2>/dev/null || true)
if [ -z "$ACTIVE_ACCOUNT" ]; then
  echo "[!] WARNING: Could not detect active gcloud account on host."
fi

# 4. Run the container
echo "[+] Launching attila:v${VERSION}..."
docker run $DOCKER_FLAGS \
  -e PROJECT_ID="$PROJECT_ID" \
  -e AGENT_PROMPT="$PROMPT" \
  -e GEMINI_MODEL="${GEMINI_MODEL:-}" \
  -e CLOUDSDK_CORE_ACCOUNT="$ACTIVE_ACCOUNT" \
  -v "$(pwd)/memory/$PROJECT_ID":/memory \
  -v "$USER_HOME/.config/gcloud/application_default_credentials.json:/adc.json:ro" \
  -v "$USER_HOME/.config/gcloud/credentials.db:/gcloud-credentials-db-ro/credentials.db:ro" \
  "attila:v${VERSION}"
