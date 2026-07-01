#!/bin/bash
# A.TT.I.L.A. Bash Provisioning Script
# "Sbabbari, prima provvisioniamo e poi discutiamo!" 🗡️

## Note: this is a placeholder script before moving to Terraform

set -euo pipefail

# Load env file if provided, otherwise default to .env
ENV_FILE="${3:-.env}"
if [ -f "$ENV_FILE" ]; then
  echo "[+] Loading env from $ENV_FILE"
  # Export variables, ignoring comments
  export $(grep -v '^#' "$ENV_FILE" | xargs)
fi

PROJECT_ID=${PROJECT_ID:-$1}
GCP_IDENTITY=${GCP_IDENTITY:-$2}

if [ -z "$PROJECT_ID" ]; then
  echo "[-] ERROR: PROJECT_ID is not set. Define it in .env or pass as argument."
  exit 1
fi

echo "[+] Starting Bash provisioning for project: $PROJECT_ID"
echo "[+] Using identity: $GCP_IDENTITY"

# 1. Enable APIs
echo "[+] Enabling required APIs..."
gcloud services enable \
  iam.googleapis.com \
  storage.googleapis.com \
  pubsub.googleapis.com \
  cloudresourcemanager.googleapis.com \
  --project="$PROJECT_ID"

# 2. Create Service Account
echo "[+] Creating Service Account..."
if gcloud iam service-accounts describe "safe-sre-investigator@$PROJECT_ID.iam.gserviceaccount.com" --project="$PROJECT_ID" >/dev/null 2>&1; then
  echo "[!] Service Account safe-sre-investigator already exists, skipping creation."
else
  gcloud iam service-accounts create safe-sre-investigator \
    --description="Restricted Service Account used by spapparo agent for read-only SRE investigations." \
    --display-name="Safe SRE Investigator Service Account" \
    --project="$PROJECT_ID"
fi
echo "[+] Waiting 10 seconds for Service Account propagation..."
sleep 10

# 3. Grant Required Roles to Service Account
echo "[+] Granting required roles to Service Account..."
for role in \
  roles/viewer \
  roles/iam.securityReviewer \
  roles/logging.viewer \
  roles/monitoring.viewer \
  roles/browser \
  roles/container.viewer \
  roles/compute.viewer \
  roles/storage.objectViewer \
  roles/run.viewer \
  roles/monitoring.dashboardEditor \
  roles/bigquery.user \
  roles/bigquery.dataViewer; do
  echo "  [+] Granting $role..."
  gcloud projects add-iam-policy-binding "$PROJECT_ID" \
    --member="serviceAccount:safe-sre-investigator@$PROJECT_ID.iam.gserviceaccount.com" \
    --role="$role" \
    --quiet >/dev/null
done

# 4. Grant Impersonation (Best Effort)
if [ -n "$GCP_IDENTITY" ]; then
  echo "[+] Granting Service Account Token Creator to $GCP_IDENTITY (Best Effort)..."
  if gcloud iam service-accounts add-iam-policy-binding "safe-sre-investigator@$PROJECT_ID.iam.gserviceaccount.com" \
    --member="user:$GCP_IDENTITY" \
    --role="roles/iam.serviceAccountTokenCreator" \
    --project="$PROJECT_ID" --quiet >/dev/null 2>&1; then
    echo "[+] Successfully granted impersonation rights."
  else
    echo "[!] WARNING: Failed to grant impersonation rights. You may not have permission."
    echo "    Please ask an Owner (like Madhavi) to manually grant the role:"
    echo "    'roles/iam.serviceAccountTokenCreator' to $GCP_IDENTITY on the SA."
  fi
else
  echo "[!] WARNING: GCP_IDENTITY not set in .env. Skipping impersonation setup."
fi

# 5. Create GCS Buckets
echo "[+] Creating GCS Buckets..."
# Private
if gcloud storage buckets describe "gs://$PROJECT_ID-attila-private" --project="$PROJECT_ID" >/dev/null 2>&1; then
  echo "[!] Private bucket gs://$PROJECT_ID-attila-private already exists."
else
  gcloud storage buckets create "gs://$PROJECT_ID-attila-private" --project="$PROJECT_ID" --location=europe-west1
fi

# Public (Note: Private access enforced, named public for reports)
if gcloud storage buckets describe "gs://$PROJECT_ID-attila-public" --project="$PROJECT_ID" >/dev/null 2>&1; then
  echo "[!] Public bucket gs://$PROJECT_ID-attila-public already exists."
else
  gcloud storage buckets create "gs://$PROJECT_ID-attila-public" --project="$PROJECT_ID" --location=europe-west1
fi

# Grant SA access to private bucket
echo "[+] Granting SA access to private bucket..."
gcloud storage buckets add-iam-policy-binding "gs://$PROJECT_ID-attila-private" \
  --member="serviceAccount:safe-sre-investigator@$PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/storage.objectAdmin" \
  --quiet >/dev/null

# 6. Create Pub/Sub Topic
echo "[+] Creating Pub/Sub Topic..."
if gcloud pubsub topics describe attila-investigations --project="$PROJECT_ID" >/dev/null 2>&1; then
  echo "[!] Pub/Sub topic attila-investigations already exists."
else
  gcloud pubsub topics create attila-investigations --project="$PROJECT_ID"
fi

# 7. Grant Vertex AI User role to Service Account (for Vertex AI API access)
echo "[+] Granting Vertex AI User role to Service Account..."
gcloud projects add-iam-policy-binding "$PROJECT_ID" \
  --member="serviceAccount:safe-sre-investigator@$PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/aiplatform.user" \
  --quiet >/dev/null

echo "[+] Bash provisioning completed!"
