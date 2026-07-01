#!/bin/bash
# spapparo Docker Entrypoint
# "Noi sbabbari, prima rademo al suolo e poi discutiamo!" 🗡️

set -e

# Color codes
GREEN='\e[1;32m'
BLUE='\e[1;36m'
NC='\e[0m' # No Color

SA_EMAIL="${SA_EMAIL:-safe-sre-investigator@$PROJECT_ID.iam.gserviceaccount.com}"
export GOOGLE_IMPERSONATE_SERVICE_ACCOUNT="$SA_EMAIL"

echo -e "===================================================="
echo -e "🗡️  ${GREEN}Spapparo Barbarian Agent starting up...${NC}"
echo -e "===================================================="
echo -e "🟢 ${GREEN}PROJECT ID:${NC} ${BLUE}$PROJECT_ID${NC}"
echo -e "🟢 ${GREEN}HOST IDENTITY:${NC} ${BLUE}${CLOUDSDK_CORE_ACCOUNT:-None}${NC}"
echo -e "🟢 ${GREEN}IMPERSONATING:${NC} ${BLUE}$SA_EMAIL${NC}"
echo -e "===================================================="

# 1. Configure credentials
# Set GOOGLE_APPLICATION_CREDENTIALS for Vertex AI SDK
if [ -f /adc.json ]; then
  echo "[+] Configuring SDK with mounted ADC..."
  export GOOGLE_APPLICATION_CREDENTIALS=/adc.json
fi

# Set up gcloud credentials by copying the mounted credentials.db
if [ -f /gcloud-credentials-db-ro/credentials.db ]; then
  echo "[+] Copying gcloud credentials.db to writable location..."
  mkdir -p /root/.config/gcloud
  cp /gcloud-credentials-db-ro/credentials.db /root/.config/gcloud/credentials.db
  chmod u+w /root/.config/gcloud/credentials.db
  
  if [ -n "${CLOUDSDK_CORE_ACCOUNT:-}" ]; then
    echo "[+] Setting active gcloud account to: $CLOUDSDK_CORE_ACCOUNT"
    gcloud config set account "$CLOUDSDK_CORE_ACCOUNT"
  fi
else
  echo "[!] WARNING: No gcloud credentials.db found. gcloud commands may fail."
fi

# 2. Configure gcloud to impersonate the Service Account
echo "[+] Configuring gcloud to impersonate Service Account: $SA_EMAIL"
gcloud config set project "$PROJECT_ID"
gcloud config set auth/impersonate_service_account "$SA_EMAIL"

# Quick verification step to shorten feedback loop
echo "[+] Verifying storage access (gcloud storage ls)..."
gcloud storage ls

# 3. Configure gemini-cli to use Vertex AI
export GOOGLE_CLOUD_PROJECT="$PROJECT_ID"
export GOOGLE_CLOUD_LOCATION="us-central1"
export GOOGLE_GENAI_USE_VERTEXAI=true
export GEMINI_MODEL="${GEMINI_MODEL:-gemini-2.5-flash}"

# Ensure gemini-cli config directory exists and pre-trust the /app workspace
mkdir -p /root/.gemini
echo '{"/app": "TRUST_FOLDER"}' > /root/.gemini/trustedFolders.json

# Verify impersonation works for gcloud
echo "[+] Verifying Service Account impersonation..."
if gcloud config get-value auth/impersonate_service_account 2>/dev/null | grep -q "$SA_EMAIL"; then
  echo "[+] Successfully impersonating $SA_EMAIL"
else
  echo "[!] WARNING: Impersonation verification failed. gcloud commands may fail."
fi

# Create safe_gcloud wrapper to satisfy the SRE extension
echo "[+] Creating safe_gcloud wrapper..."
echo -e '#!/bin/bash\nshift\nexec gcloud "$@"' > /usr/local/bin/safe_gcloud
chmod +x /usr/local/bin/safe_gcloud

# If arguments are passed, execute them instead of the default agent run
if [ $# -gt 0 ]; then
  echo -e "[+] Executing custom command inside container: ${BLUE}$*${NC}"
  echo "----------------------------------------------------"
  exec "$@"
else
  # Construct the prompt
  if [ -n "$AGENT_PROMPT" ]; then
    PROMPT="$AGENT_PROMPT"
    echo "[+] Using custom prompt: $PROMPT"
  else
    PROMPT="Perform a GCP discovery of the project $PROJECT_ID. Identify all active resources (GCS buckets, Cloud Run services, GKE clusters, etc.). Write your findings in a clear markdown report to /app/memory/discovery/\$(date +%Y-%m-%d)-discovery.md and compile the resource graph into /app/memory/architecture.json. Keep it detailed but concise."
    echo "[+] Using default discovery prompt."
  fi

  # Run gemini-cli in YOLO mode (-y) to auto-approve discovery commands
  exec gemini -y -p "$PROMPT"
fi
