#!/bin/bash
# attila test-config
# "A come atroce, T come terremoto..." 🗡️
# Verifies that your GCP project, Service Account, Impersonation, and Gemini CLI are correctly configured.

set -euo pipefail

# Color codes
RED='\e[31m'
GREEN='\e[32m'
YELLOW='\e[33m'
BLUE='\e[36m'
BOLD='\e[1m'
NC='\e[0m' # No Color

echo -e "${BOLD}====================================================${NC}"
echo -e "${BOLD}🗡️  Attila Config Validator starting...${NC}"
echo -e "${BOLD}====================================================${NC}"

# 1. Load environment variables
ENV_FILE="${1:-.env}"
if [ -f "$ENV_FILE" ]; then
  echo -e "[+] Loading environment from ${BLUE}$ENV_FILE${NC}..."
  set -a
  source "$ENV_FILE"
  set +a
else
  echo -e "${RED}[-] Error: Environment file $ENV_FILE not found.${NC}"
  exit 1
fi

# Check for up-to-date marker file to skip tests
MARKER_FILE="${ENV_FILE}.ok"
FORCE_TEST="${FORCE_TEST:-false}"

if [ "$FORCE_TEST" = "false" ] && [ -f "$MARKER_FILE" ] && [ "$MARKER_FILE" -nt "$ENV_FILE" ]; then
  echo -e "${GREEN}✓ Configuration checks already passed for $ENV_FILE (marker $MARKER_FILE is up-to-date).${NC}"
  echo -e "  To force re-running tests, run: ${BOLD}FORCE_TEST=true just test-config $ENV_FILE${NC}"
  exit 0
fi

# Map GCP_IDENTITY to CLOUDSDK_CORE_ACCOUNT if present
if [ -z "${CLOUDSDK_CORE_ACCOUNT:-}" ] && [ -n "${GCP_IDENTITY:-}" ]; then
  export CLOUDSDK_CORE_ACCOUNT="$GCP_IDENTITY"
fi

if [ -n "${CLOUDSDK_CORE_ACCOUNT:-}" ]; then
  export CLOUDSDK_CORE_ACCOUNT
fi

if [ -z "${PROJECT_ID:-}" ]; then
  echo -e "${RED}[-] Error: PROJECT_ID is not set in $ENV_FILE.${NC}"
  exit 1
fi

SA_EMAIL="safe-sre-investigator@${PROJECT_ID}.iam.gserviceaccount.com"

# Determine host identity for logging
HOST_IDENTITY="${CLOUDSDK_CORE_ACCOUNT:-}"
if [ -z "$HOST_IDENTITY" ]; then
  HOST_IDENTITY=$(gcloud config get-value account 2>/dev/null || echo "Unknown")
fi

echo -e "🟢 ${GREEN}PROJECT ID:${NC} ${BLUE}$PROJECT_ID${NC}"
echo -e "🟢 ${GREEN}HOST IDENTITY:${NC} ${BLUE}$HOST_IDENTITY${NC}"
echo -e "🟢 ${GREEN}TARGET SA:${NC} ${BLUE}$SA_EMAIL${NC}"
echo -e "${BOLD}----------------------------------------------------${NC}"

# Helper to run gcloud on host without default impersonation interfering with tests
run_host_gcloud() {
  CLOUDSDK_AUTH_IMPERSONATE_SERVICE_ACCOUNT="" gcloud "$@"
}

# ====================================================
# TEST 1: Service Account Verification
# ====================================================
echo -e "${BOLD}💻 [Test 1/8] Verifying Service Account existence...${NC}"
if run_host_gcloud iam service-accounts describe "$SA_EMAIL" --project="$PROJECT_ID" >/dev/null 2>&1; then
  echo -e "  ${GREEN}✓ Service Account exists.${NC}"
else
  echo -e "  ${RED}✗ Service Account $SA_EMAIL does not exist or is not accessible.${NC}"
  echo -e "    Please run setup-infra or ensure you have correct permissions.${NC}"
  exit 1
fi

# ====================================================
# TEST 2: Vertex AI API Verification
# ====================================================
echo -e "${BOLD}💻 [Test 2/8] Verifying Vertex AI API...${NC}"
if run_host_gcloud services list --project="$PROJECT_ID" --enabled --filter="config.name:aiplatform.googleapis.com" --format="value(config.name)" 2>/dev/null | grep -q "aiplatform.googleapis.com"; then
  echo -e "  ${GREEN}✓ Vertex AI API (aiplatform.googleapis.com) is ENABLED.${NC}"
else
  echo -e "  ${RED}✗ Vertex AI API is NOT enabled in project $PROJECT_ID.${NC}"
  echo -e "    Please enable it: gcloud services enable aiplatform.googleapis.com --project=$PROJECT_ID${NC}"
  exit 1
fi

if [ -n "${GEMINI_API_KEY:-}" ]; then
  echo -e "  ${YELLOW}i GEMINI_API_KEY is configured (Developer API).${NC}"
else
  echo -e "  ${BLUE}i GEMINI_API_KEY is not set (using Vertex AI/ADC).${NC}"
fi

# ====================================================
# TEST 3: GCS Buckets and Pub/Sub Topic Verification
# ====================================================
echo -e "${BOLD}💻 [Test 3/8] Verifying GCS Buckets and Pub/Sub Topic...${NC}"
PRIVATE_BUCKET="gs://${PROJECT_ID}-attila-private"
PUBLIC_BUCKET="gs://${PROJECT_ID}-attila-public"
TOPIC_NAME="attila-investigations"

INFRA_OK=true
if ! CLOUDSDK_AUTH_IMPERSONATE_SERVICE_ACCOUNT="" gcloud storage buckets describe "$PRIVATE_BUCKET" --project="$PROJECT_ID" >/dev/null 2>&1; then
  echo -e "  ${RED}✗ Private bucket $PRIVATE_BUCKET does not exist or is not accessible.${NC}"
  INFRA_OK=false
fi
if ! CLOUDSDK_AUTH_IMPERSONATE_SERVICE_ACCOUNT="" gcloud storage buckets describe "$PUBLIC_BUCKET" --project="$PROJECT_ID" >/dev/null 2>&1; then
  echo -e "  ${RED}✗ Public bucket $PUBLIC_BUCKET does not exist or is not accessible.${NC}"
  INFRA_OK=false
fi
if ! CLOUDSDK_AUTH_IMPERSONATE_SERVICE_ACCOUNT="" gcloud pubsub topics describe "$TOPIC_NAME" --project="$PROJECT_ID" >/dev/null 2>&1; then
  echo -e "  ${RED}✗ Pub/Sub topic $TOPIC_NAME does not exist or is not accessible.${NC}"
  INFRA_OK=false
fi

if [ "$INFRA_OK" = true ]; then
  echo -e "  ${GREEN}✓ GCS Buckets and Pub/Sub Topic exist.${NC}"
else
  echo -e "  ${YELLOW}i Some infrastructure resources are missing. You may need to run setup-infra.${NC}"
  exit 1
fi

# ====================================================
# TEST 4: Impersonation Verification
# ====================================================
echo -e "${BOLD}💻 [Test 4/8] Verifying Service Account Impersonation on Host...${NC}"
# Attempt a cheap call impersonating the SA
if CLOUDSDK_AUTH_IMPERSONATE_SERVICE_ACCOUNT="" gcloud projects describe "$PROJECT_ID" --impersonate-service-account="$SA_EMAIL" >/dev/null 2>&1; then
  echo -e "  ${GREEN}✓ Impersonation works. Host identity can act as $SA_EMAIL.${NC}"
else
  echo -e "  ${RED}✗ Impersonation FAILED.${NC}"
  echo -e "    Ensure $HOST_IDENTITY has 'roles/iam.serviceAccountTokenCreator' on $SA_EMAIL.${NC}"
  echo -e "    Run: gcloud iam service-accounts add-iam-policy-binding $SA_EMAIL \\${NC}"
  echo -e "           --member=\"user:$HOST_IDENTITY\" --role=\"roles/iam.serviceAccountTokenCreator\" --project=$PROJECT_ID${NC}"
  exit 1
fi

# ====================================================
# TEST 5: Gemini API Key Verification (Developer API)
# ====================================================
if [ -n "${GEMINI_API_KEY:-}" ]; then
  echo -e "${BOLD}💻 [Test 5/8] Verifying Gemini API Key...${NC}"
  RESPONSE=$(curl -s -w "\n%{http_code}" -H "Content-Type: application/json" \
    "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-lite:generateContent?key=${GEMINI_API_KEY}" \
    -d '{"contents": [{"parts":[{"text": "write exactly one word: success"}]}]}')
  
  HTTP_STATUS=$(echo "$RESPONSE" | tail -n 1)
  BODY=$(echo "$RESPONSE" | head -n -1)
  
  if [ "$HTTP_STATUS" = "200" ] && echo "$BODY" | grep -qi "success"; then
    echo -e "  ${GREEN}✓ Gemini API Key is working.${NC}"
  elif [ "$HTTP_STATUS" = "503" ]; then
    echo -e "  ${GREEN}✓ Gemini API Key is working${NC} ${YELLOW}(but backend is currently overloaded, HTTP 503).${NC}"
  else
    echo -e "  ${RED}✗ Gemini API Key verification FAILED (HTTP $HTTP_STATUS).${NC}"
    echo -e "    Response: $BODY${NC}"
    exit 1
  fi
else
  echo -e "${BOLD}💻 [Test 5/8] Verifying Gemini API Key...${NC}"
  echo -e "  ${BLUE}i GEMINI_API_KEY not set, skipping.${NC}"
fi

# ====================================================
# TEST 6: Container gcloud Verification
# ====================================================
echo -e "${BOLD}🐳 [Test 6/8] Verifying gcloud inside container...${NC}"

# Resolve paths for Docker mounts
ADC_PATH="${HOME}/.config/gcloud/application_default_credentials.json"
CRED_DB_PATH="${HOME}/.config/gcloud/credentials.db"

if [ ! -f "$ADC_PATH" ]; then
  echo -e "  ${RED}✗ ADC file not found at $ADC_PATH. Run 'gcloud auth application-default login'${NC}"
  exit 1
fi

if [ ! -f "$CRED_DB_PATH" ]; then
  echo -e "  ${RED}✗ gcloud credentials.db not found at $CRED_DB_PATH.${NC}"
  exit 1
fi

echo -e "  [+] Launching container to verify gcloud storage access (timeout 30s)..."
if timeout 30 docker run --rm \
  -e PROJECT_ID="$PROJECT_ID" \
  -e CLOUDSDK_CORE_ACCOUNT="$HOST_IDENTITY" \
  -v "$ADC_PATH":/adc.json:ro \
  -v "$CRED_DB_PATH":/gcloud-credentials-db-ro/credentials.db:ro \
  attila:v0.1.0 \
  gcloud storage buckets list --project="$PROJECT_ID" \
  > /tmp/attila-test-container-gcloud.log 2>&1; then
  
  if grep -q "gs://" /tmp/attila-test-container-gcloud.log; then
    echo -e "  ${GREEN}✓ gcloud inside container authenticated and listed buckets successfully.${NC}"
  else
    echo -e "  ${RED}✗ gcloud inside container succeeded but returned no buckets or unexpected output.${NC}"
    echo -e "    Output: $(cat /tmp/attila-test-container-gcloud.log)${NC}"
    exit 1
  fi
else
  EXIT_CODE=$?
  if [ $EXIT_CODE -eq 124 ]; then
    echo -e "  ${RED}✗ gcloud inside container TIMED OUT (30s).${NC}"
  else
    echo -e "  ${RED}✗ gcloud inside container FAILED (exit code $EXIT_CODE).${NC}"
  fi
  echo -e "    Check logs at: /tmp/attila-test-container-gcloud.log${NC}"
  exit 1
fi

# ====================================================
# TEST 7: Harness Execution (Docker + Gemini CLI Cheap Call)
# ====================================================
echo -e "${BOLD}🐳 [Test 7/8] Verifying Harness Authentication (Docker + Gemini CLI)...${NC}"
echo -e "  [+] Launching test container to run a cheap Gemini query (timeout 30s)..."
# Run a very cheap query to verify end-to-end auth
if timeout 30 docker run --rm \
  -e PROJECT_ID="$PROJECT_ID" \
  -e CLOUDSDK_CORE_ACCOUNT="$HOST_IDENTITY" \
  -e GEMINI_MODEL="${GEMINI_MODEL:-gemini-2.5-flash}" \
  -v "$ADC_PATH":/adc.json:ro \
  -v "$CRED_DB_PATH":/gcloud-credentials-db-ro/credentials.db:ro \
  attila:v0.1.0 \
  gemini -y -p "write exactly one word: success" > /tmp/attila-test-auth.log 2>&1; then
  
  if grep -qi "success" /tmp/attila-test-auth.log; then
    echo -e "  ${GREEN}✓ Harness authenticated successfully! Gemini responded.${NC}"
  else
    echo -e "  ${YELLOW}! Container ran, but response was unexpected. Check logs at /tmp/attila-test-auth.log${NC}"
    tail -n 5 /tmp/attila-test-auth.log
  fi
else
  EXIT_CODE=$?
  if [ $EXIT_CODE -eq 124 ]; then
    echo -e "  ${RED}✗ Harness authentication TIMED OUT (30s).${NC}"
  else
    echo -e "  ${RED}✗ Harness authentication FAILED (exit code $EXIT_CODE).${NC}"
  fi
  echo -e "    Check logs at: /tmp/attila-test-auth.log${NC}"
  exit 1
fi

# ====================================================
# TEST 8: Harness End-to-End (List Buckets)
# ====================================================
echo -e "${BOLD}🐳 [Test 8/8] Verifying Harness End-to-End (List Buckets)...${NC}"
echo -e "  [+] Launching container to list buckets via Gemini (timeout 60s)..."

if timeout 60 docker run --rm \
  -e PROJECT_ID="$PROJECT_ID" \
  -e CLOUDSDK_CORE_ACCOUNT="$HOST_IDENTITY" \
  -e GEMINI_MODEL="${GEMINI_MODEL:-gemini-2.5-flash}" \
  -v "$ADC_PATH":/adc.json:ro \
  -v "$CRED_DB_PATH":/gcloud-credentials-db-ro/credentials.db:ro \
  attila:v0.1.0 \
  gemini -y -p "The safe-sre-investigator setup is ALREADY complete. Do NOT run the setup script. List the GCS buckets in the project $PROJECT_ID and show them. Conclude with 'E2E_SUCCESS' if you succeeded." > /tmp/attila-test-e2e.log 2>&1; then
  
  if grep -qi "E2E_SUCCESS" /tmp/attila-test-e2e.log; then
    echo -e "  ${GREEN}✓ E2E test passed! Gemini listed buckets.${NC}"
    echo -e "  [+] Buckets found by agent:"
    grep -a -E "gs://" /tmp/attila-test-e2e.log | sed 's/^/    /' || true
  else
    echo -e "  ${RED}✗ E2E test FAILED. Response was unexpected. Check logs at /tmp/attila-test-e2e.log${NC}"
    tail -n 10 /tmp/attila-test-e2e.log
    exit 1
  fi
else
  EXIT_CODE=$?
  if [ $EXIT_CODE -eq 124 ]; then
    echo -e "  ${RED}✗ E2E test TIMED OUT (60s).${NC}"
  else
    echo -e "  ${RED}✗ E2E test FAILED to execute (exit code $EXIT_CODE).${NC}"
  fi
  echo -e "    Check logs at: /tmp/attila-test-e2e.log${NC}"
  exit 1
fi

# Create or update the success marker file
touch "$MARKER_FILE"

echo -e "${BOLD}====================================================${NC}"
echo -e "${GREEN}${BOLD}🎉 All configuration checks PASSED! Attila is ready to pillage!${NC}"
echo -e "${BOLD}====================================================${NC}"
