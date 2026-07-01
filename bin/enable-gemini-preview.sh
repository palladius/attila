#!/bin/bash
# Helper script to enable the Gemini Preview Release Channel (EXPERIMENTAL) for a GCP project.
# Requires roles/cloudaicompanion.settingsAdmin on the project.

set -o pipefail
set -e

PROJECT_ID="${1:-}"

if [ -z "$PROJECT_ID" ]; then
  # Try to detect from active gcloud config if not provided
  PROJECT_ID=$(gcloud config get-value project 2>/dev/null)
fi

if [ -z "$PROJECT_ID" ]; then
  echo "Error: PROJECT_ID is required."
  echo "Usage: $0 <project_id>"
  exit 1
fi

echo "[+] Detecting active account..."
ACTIVE_ACCOUNT=$(gcloud config get-value account 2>/dev/null)
echo "[+] Using account: $ACTIVE_ACCOUNT"

echo "[+] Obtaining access token..."
TOKEN=$(gcloud auth print-access-token)

echo "[+] Enabling Preview Release Channel (EXPERIMENTAL) for project: $PROJECT_ID..."
response=$(curl -s -w "\n%{http_code}" -X POST \
  -H "Authorization: Bearer $TOKEN" \
  -H 'Content-Type: application/json' \
  -d '{"release_channel": "EXPERIMENTAL"}' \
  "https://cloudaicompanion.googleapis.com/v1/projects/${PROJECT_ID}/locations/global/releaseChannelSettings?release_channel_setting_id=default")

http_code=$(echo "$response" | tail -n1)
body=$(echo "$response" | head -n -1)

if [ "$http_code" -eq 200 ]; then
  echo "[+] Success! Preview Release Channel enabled."
  echo "$body"
else
  echo "[-] Failed to enable Preview Release Channel (HTTP $http_code)."
  echo "$body"
  echo "[-] Make sure you have 'roles/cloudaicompanion.settingsAdmin' on the project."
  exit 1
fi
