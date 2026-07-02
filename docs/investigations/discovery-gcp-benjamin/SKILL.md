---
name: discovery-gcp-benjamin
description: Perform structured GCP resource discovery and security auditing using sequential gcloud queries, generating a JSON catalog and a security Wiki.
---

# Skill: Benjamin-Style GCP Discovery & Security Audit

This skill describes how to perform a structured, multi-service GCP resource discovery and security audit. Unlike broad asset inventory searches, this method queries specific resource APIs sequentially, performs targeted security checks, and generates a structured JSON catalog and a Markdown Wiki.

## 1. Discovery Commands

Perform the following `gcloud` queries sequentially for the target `PROJECT_ID`. Ensure you use `--format=json` to capture full metadata.

### 1.1 GCE VM Instances
Query all VM instances in the project:
```bash
gcloud compute instances list --project=PROJECT_ID --format=json
```
*   **Filtering:** Ignore instances starting with `gke-` (managed by GKE) or containing `dataproc` (managed by Dataproc) to focus on user-managed VMs.

### 1.2 Cloud Run Services
Query all Cloud Run services:
```bash
gcloud run services list --project=PROJECT_ID --format=json
```
For each service found, query its IAM policy to check access controls:
```bash
gcloud run services get-iam-policy SERVICE_NAME --project=PROJECT_ID --region=REGION --format=json
```

### 1.3 GKE Clusters
Query all GKE clusters:
```bash
gcloud container clusters list --project=PROJECT_ID --format=json
```

### 1.4 Cloud SQL Instances
Query all Cloud SQL database instances:
```bash
gcloud sql instances list --project=PROJECT_ID --format=json
```

### 1.5 GCS Buckets
Query all Cloud Storage buckets:
```bash
gcloud storage buckets list --project=PROJECT_ID --format=json
```

### 1.6 VPC Networks
Query all VPC networks:
```bash
gcloud compute networks list --project=PROJECT_ID --format=json
```

---

## 2. Security Audit Rules

For each resource discovered, apply the following audit rules in Python/Bash to determine if it is **vulnerable** (exposed):

| Resource Type | Vulnerability Check | Audit Warning Message |
| :--- | :--- | :--- |
| **GCE VM** | Has an external IP address (`networkInterfaces[].accessConfigs[].natIP` is present) | `⚠️ EXPOSED: Bound to public IP <EXTERNAL_IP>` |
| **Cloud Run** | IAM policy contains `allUsers` bound to `roles/run.invoker` | `⚠️ EXPOSED: Unauthenticated public access (allUsers invoker)` |
| **GKE Cluster** | `privateClusterConfig.enablePrivateEndpoint` is NOT `true` (public control plane enabled) | `⚠️ EXPOSED: Public GKE control plane endpoint access enabled` |
| **Cloud SQL** | `ipConfiguration.ipv4Enabled` is `true` AND `ipConfiguration.authorizedNetworks` is empty | `⚠️ EXPOSED: Public IP enabled with no authorized networks restrictions` |
| **GCS Bucket** | `public_access_prevention` is NOT set to `enforced` | `⚠️ EXPOSED: Uniform bucket public access prevention is not enforced` |
| **VPC Network** | Network name is `default` OR `autoCreateSubnetworks` is `true` | `⚠️ EXPOSED: Default network contains auto-subnets and standard wide ingress firewall rules` |

---

## 3. Output Organization

Save the discovery outputs under the following structure:
📂 `private/discovery/<PROJECT_ID>/` (or `memory/<PROJECT_ID>/discovery/` depending on gitignore preferences)

### 3.1 `discover.json`
A JSON array containing all audited resources.
```json
[
  {
    "name": "frontend-vm",
    "type": "gce_vm",
    "location": "us-central1-a",
    "status": "RUNNING",
    "vulnerable": true,
    "warning": "⚠️ EXPOSED: Bound to public IP 34.135.120.45",
    "console_url": "https://console.cloud.google.com/compute/instancesDetail/zones/us-central1-a/instances/frontend-vm?project=PROJECT_ID",
    "metadata": {
      "internal_ip": "10.128.0.5",
      "external_ip": "34.135.120.45"
    }
  }
]
```

### 3.2 `wiki.md`
A Markdown document summarizing the audit.
```markdown
# GCP Resource Catalog: PROJECT_ID
Auto-generated on **YYYY-MM-DD HH:MM:SS UTC**

## Executive SRE Audit Summary
🚨 **VULNERABILITY WARNING**: Found **N** exposed/vulnerable resources out of **M** analyzed assets. Action required!

## Discovered Resource Catalog
| Type | Name | Location | Status | Audit Warning |
| --- | --- | --- | --- | --- |
| 🖥️ Compute VM | `frontend-vm` | `us-central1-a` | `RUNNING` | **⚠️ EXPOSED: Bound to public IP 34.135.120.45** |
| 🪣 GCS Bucket | `assets-bucket` | `US-CENTRAL1` | `ACTIVE` | ✅ SAFE |

## Detailed Resource Metadata
### `frontend-vm` (gce_vm)
- **Location**: `us-central1-a`
- **Status**: `RUNNING`
- **Audited Vulnerable**: `true`
- **Audit Warning**: **⚠️ EXPOSED: Bound to public IP 34.135.120.45**
- **Metadata Details**:
  ```json
  {
      "internal_ip": "10.128.0.5",
      "external_ip": "34.135.120.45"
  }
  ```
```

---

## 4. How to Execute with Attila

When Attila is tasked with performing a Benjamin-style discovery:
1.  **Write a Python Script:** Attila should dynamically generate a Python script (e.g., `generate_benjamin_reports.py`) in its workspace.
2.  **Implement subprocess calls:** The script should use `subprocess.run` to execute the `gcloud` commands listed in Section 1.
3.  **Parse and Audit:** Implement the audit rules from Section 2 in Python.
4.  **Write Outputs:** Write the `discover.json` and `wiki.md` to the designated output directory.
5.  **Clean up:** Remove the temporary script after execution.
