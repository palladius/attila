#!/bin/bash
# spapparo Docker Entrypoint
# "Noi sbabbari, prima rademo al suolo e poi discutiamo!" 🗡️

set -e

echo "===================================================="
echo "🗡️  Spapparo Barbarian Agent starting up..."
echo "===================================================="

# Validate required env vars
if [ -z "$PROJECT_ID" ]; then
  echo "[-] ERROR: PROJECT_ID environment variable is not set."
  exit 1
fi

if [ -z "$GEMINI_API_KEY" ]; then
  echo "[-] ERROR: GEMINI_API_KEY environment variable is not set."
  exit 1
fi

export GEMINI_API_KEY="$GEMINI_API_KEY"

# Authenticate GCP using Service Account if key file is present
SA_KEY_PATH="/etc/gcp/sa-key.json"
if [ -f "$SA_KEY_PATH" ]; then
  echo "[+] Found Service Account key at $SA_KEY_PATH"
  echo "[+] Authenticating gcloud..."
  
  # Extract client email from JSON to dynamically get the service account name
  SA_EMAIL=$(python3 -c "import json; print(json.load(open('$SA_KEY_PATH'))['client_email'])" 2>/dev/null || echo "safe-sre-investigator@$PROJECT_ID.iam.gserviceaccount.com")
  
  gcloud auth activate-service-account "$SA_EMAIL" --key-file="$SA_KEY_PATH"
  gcloud config set project "$PROJECT_ID"
  export GOOGLE_APPLICATION_CREDENTIALS="$SA_KEY_PATH"
  
  echo "[+] gcloud successfully authenticated as $SA_EMAIL"
else
  echo "[!] WARNING: No Service Account key found at $SA_KEY_PATH."
  echo "    gcloud commands might fail inside the container."
fi

# Install the SRE extension for gemini-cli
echo "[+] Installing Gemini SRE extension..."
gemini extensions install https://github.com/gemini-cli-extensions/sre || echo "[!] Extension install failed, continuing..."

# Execute the Gemini CLI with the prompt
echo "[+] Launching Gemini CLI discovery..."
echo "----------------------------------------------------"

# Construct the prompt
PROMPT="Perform a GCP discovery of the project $PROJECT_ID. Identify all active resources (GCS buckets, Cloud Run services, GKE clusters, etc.). Write your findings in a clear markdown report to /memory/discovery/$(date +%Y-%m-%d)-discovery.md and compile the resource graph into /memory/architecture.json. Keep it detailed but concise."

# Run gemini-cli
gemini -p "$PROMPT"

echo "----------------------------------------------------"
echo "[+] Spapparo completed the run successfully! State saved to /memory."
echo "===================================================="
