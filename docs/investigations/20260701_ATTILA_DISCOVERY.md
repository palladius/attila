# ATTILA Infrastructure Discovery - 2026-07-01

This document explains how the GCP resource discovery was performed by the ATTILA agent on the `sre-next` project, specifically how the raw resource database `sre-next_resources.json` was generated and processed.

## 1. Raw Resource Extraction (`sre-next_resources.json`)

The raw resource data was extracted by querying the **GCP Cloud Asset Inventory** using the `gcloud` CLI. 

### Identity & Permissions
The command was executed inside the `spapparo` Docker container under the impersonated Service Account:
*   **Service Account:** `safe-sre-investigator@sre-next.iam.gserviceaccount.com`
*   **Role Required:** `roles/cloudasset.viewer` (Read-only access to Cloud Asset Inventory)

### The Command
The agent executed the following command to retrieve all active resources and save them in JSON format:

```bash
gcloud asset search-all-resources \
  --scope="projects/sre-next" \
  --asset-types="storage.googleapis.com/Bucket,\
run.googleapis.com/Service,\
container.googleapis.com/Cluster,\
compute.googleapis.com/Instance,\
sqladmin.googleapis.com/Instance,\
cloudfunctions.googleapis.com/Function,\
pubsub.googleapis.com/Topic" \
  --format="json" \
  > /app/memory/discovery/sre-next_resources.json
```

### Targeted Resource Types
The query explicitly filtered for these high-level resource types:
*   **GCS Buckets**: `storage.googleapis.com/Bucket`
*   **Cloud Run Services**: `run.googleapis.com/Service`
*   **GKE Clusters**: `container.googleapis.com/Cluster`
*   **Compute Engine VMs**: `compute.googleapis.com/Instance`
*   **Cloud SQL Instances**: `sqladmin.googleapis.com/Instance`
*   **Cloud Functions**: `cloudfunctions.googleapis.com/Function`
*   **Pub/Sub Topics**: `pubsub.googleapis.com/Topic`

---

## 2. Report & Graph Generation

Once `sre-next_resources.json` was generated, the agent executed the Python script [generate_reports.py](file:///usr/local/google/home/ricc/git/attila/memory/sre-next/discovery/generate_reports.py) located in the discovery memory folder.

### What the Script Does:
1.  **Reads** `sre-next_resources.json`.
2.  **Generates Markdown Report**: Grouped by asset type, listing the display name, full resource name, location, state, and any additional attributes. Written to `memory/sre-next/discovery/2026-07-01-discovery.md`.
3.  **Compiles Architecture Graph**: Organizes the resources into a structured JSON tree. Written to `memory/architecture.json`.

---

## 3. Verification

The generated report was verified by the evaluation suite (`run_evals.py`) using `gemini-2.5-flash` to ensure all expected infrastructure components (specifically the project ID `sre-next`) were correctly identified. The evaluation passed with a score of `1.00`.
