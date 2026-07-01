#!/bin/bash
# A.TT.I.L.A. Generic Container Runner
# Co-authored by Jetski
#
# Usage: ./bin/docker-run.sh <env_file> [command] [args...]
# Example: ./bin/docker-run.sh .env.altostrat bash
#          ./bin/docker-run.sh .env.pbt gemini

set -euo pipefail

# Preserve critical env vars if they are already set in the host environment
PRESERVED_PROJECT_ID="${PROJECT_ID:-}"
PRESERVED_SA_EMAIL="${SA_EMAIL:-}"
PRESERVED_GCP_IDENTITY="${GCP_IDENTITY:-}"

ENV_FILE="${1:-.env}"
shift # Remove env_file from arguments, remaining are the command to run inside the container

if [ -f "$ENV_FILE" ]; then
  echo "[+] Loading environment from $ENV_FILE..."
  set -a
  source "$ENV_FILE"
  set +a
else
  echo "[!] WARNING: Environment file $ENV_FILE not found."
fi

# Restore preserved values if they were set in the host environment
if [ -n "$PRESERVED_PROJECT_ID" ]; then PROJECT_ID="$PRESERVED_PROJECT_ID"; fi
if [ -n "$PRESERVED_SA_EMAIL" ]; then SA_EMAIL="$PRESERVED_SA_EMAIL"; fi
if [ -n "$PRESERVED_GCP_IDENTITY" ]; then GCP_IDENTITY="$PRESERVED_GCP_IDENTITY"; fi

if [ -z "${PROJECT_ID:-}" ]; then
  echo "[-] ERROR: PROJECT_ID is not set in $ENV_FILE"
  exit 1
fi

# Resolve the active gcloud account (prefer GCP_IDENTITY from env file, fallback to host active)
ACTIVE_ACCOUNT="${GCP_IDENTITY:-$(gcloud config get-value account 2>/dev/null || echo "")}"
if [ -z "$ACTIVE_ACCOUNT" ]; then
  echo "[!] WARNING: No active gcloud account found."
fi

VERSION=$(cat "$(dirname "$0")/../VERSION")

# Resolve host user's home directory (supporting sudo)
USER_HOME=$HOME
if [ -n "${SUDO_USER:-}" ]; then
  USER_HOME=$(getent passwd "$SUDO_USER" | cut -d: -f6)
fi

# Resolve credential paths
ADC_PATH="$USER_HOME/.config/gcloud/application_default_credentials.json"
CRED_DB_PATH="$USER_HOME/.config/gcloud/credentials.db"

# Verify critical files exist on host
if [ ! -f "$ADC_PATH" ]; then
  echo "[-] ERROR: Application Default Credentials not found at $ADC_PATH"
  echo "    Please run: gcloud auth application-default login"
  exit 1
fi

if [ ! -f "$CRED_DB_PATH" ]; then
  echo "[!] WARNING: gcloud credentials.db not found at $CRED_DB_PATH"
  echo "    gcloud commands inside the container might fail."
fi

# Run the container, forwarding any remaining arguments
exec docker run --rm -it \
  -e PROJECT_ID="$PROJECT_ID" \
  -e SA_EMAIL="${SA_EMAIL:-}" \
  -e AGENT_PROMPT="${AGENT_PROMPT:-}" \
  -e GEMINI_MODEL="${GEMINI_MODEL:-}" \
  -e GOOGLE_CLOUD_LOCATION="${GOOGLE_CLOUD_LOCATION:-}" \
  -e GOOGLE_GENAI_USE_VERTEXAI="${GOOGLE_GENAI_USE_VERTEXAI:-}" \
  -e GEMINI_API_KEY="${GEMINI_API_KEY:-}" \
  -e CLOUDSDK_CORE_ACCOUNT="$ACTIVE_ACCOUNT" \
  -v "$(pwd)/memory/$PROJECT_ID":/app/memory \
  -v "$ADC_PATH:/adc.json:ro" \
  -v "$CRED_DB_PATH:/gcloud-credentials-db-ro/credentials.db:ro" \
  "attila:v${VERSION}" \
  "$@"
