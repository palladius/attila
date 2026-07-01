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

# 2. Determine active account (prefer env var if set in ENV_FILE)
# Map GCP_IDENTITY to CLOUDSDK_CORE_ACCOUNT if present
if [ -z "${CLOUDSDK_CORE_ACCOUNT:-}" ] && [ -n "${GCP_IDENTITY:-}" ]; then
  CLOUDSDK_CORE_ACCOUNT="$GCP_IDENTITY"
fi

if [ -z "${CLOUDSDK_CORE_ACCOUNT:-}" ]; then
  ACTIVE_ACCOUNT=$(gcloud config get-value account 2>/dev/null || echo "")
else
  ACTIVE_ACCOUNT="$CLOUDSDK_CORE_ACCOUNT"
fi

if [ -z "$ACTIVE_ACCOUNT" ]; then
  echo "[-] Error: No active gcloud account detected on host, and CLOUDSDK_CORE_ACCOUNT is not set."
  exit 1
fi

# 4. Run the container
echo "[+] Launching attila:v${VERSION}..."
docker run $DOCKER_FLAGS \
  -e PROJECT_ID="$PROJECT_ID" \
  -e AGENT_PROMPT="$PROMPT" \
  -e GEMINI_MODEL="${GEMINI_MODEL:-}" \
  -e CLOUDSDK_CORE_ACCOUNT="$ACTIVE_ACCOUNT" \
  -v "$(pwd)/memory/$PROJECT_ID":/app/memory \
  -v "$USER_HOME/.config/gcloud/application_default_credentials.json:/adc.json:ro" \
  -v "$USER_HOME/.config/gcloud/credentials.db:/gcloud-credentials-db-ro/credentials.db:ro" \
  "attila:v${VERSION}"
