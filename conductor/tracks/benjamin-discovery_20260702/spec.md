# Specification: Track - Benjamin-Style GCP Discovery (v3)

## 1. Overview
This track implements a structured, multi-service GCP resource discovery and security audit for the `sre-next` project, replicating the methodology used in the SRE ADK Benjamin project. The results will be stored as `v3` in the project's memory, allowing for a comparison with previous vanilla (v1) and skill-based (v2) discoveries.

The long-term goal is to refine this discovery process so it can eventually be contributed back to the Gemini SRE extension.

## 2. Functional Requirements
1.  **Discovery Script (`bin/run-benjamin-discovery.py`):**
    *   Must be implemented in Python and located in the repository root.
    *   Must query the following GCP services sequentially using `gcloud` (via `subprocess`):
        *   Compute Engine (VMs)
        *   Cloud Run (Services & IAM Policies)
        *   Kubernetes Engine (GKE Clusters)
        *   Cloud SQL (Instances)
        *   Cloud Storage (Buckets)
        *   VPC Networks
    *   Must filter out GKE-managed VMs (`gke-` prefix) and Dataproc nodes.
    *   Must run within the Docker container boundaries, relying on the pre-configured gcloud authentication and service account impersonation provided by `entrypoint.sh`.

2.  **Security Auditing:**
    *   The script must evaluate each discovered resource against specific security rules:
        *   VMs: Flag if they have public IPs.
        *   Cloud Run: Flag if `allUsers` has invoker role.
        *   GKE: Flag if the control plane is public.
        *   Cloud SQL: Flag if public IP is enabled with no authorized networks.
        *   GCS: Flag if Public Access Prevention is not enforced.
        *   VPC: Flag if it is the `default` network or has auto-subnets.

3.  **Output Generation:**
    *   Must write raw results to `/app/memory/discovery/sre-next_resources_v3.json`.
    *   Must write a formatted Markdown report to `/app/memory/discovery/2026-07-02-discovery_v3.md` (using the execution date).
    *   The Markdown report must include:
        *   Executive SRE Audit Summary (vulnerability counts).
        *   Summary table of all resources with safety status (✅ SAFE or 🚨 WARNING).
        *   Detailed Resource Metadata section with raw JSON blocks.

4.  **Version Comparison (One-off):**
    *   The Agent (Attila) will perform a manual comparison of the generated v3 report against the existing v1 (`2026-07-01-discovery-v1-vanilla.md`) and v2 (`2026-07-01-discovery-v2-skill.md`) reports.
    *   The comparison will be documented in a new section "## Version Comparison (v1 vs v2 vs v3)" inside `2026-07-02-discovery_v3.md`.

5.  **GitHub Issue (GHI) Creation:**
    *   A GHI will be drafted to track the integration of this structured discovery back into the SRE extension.
    *   The agent will attempt to create this issue on GitHub using the `gh` CLI.

## 3. Non-Functional Requirements
*   **Security:** Do not hardcode any credentials or sensitive project details (other than the target project ID `sre-next`).
*   **Reusability:** The script should be generic enough to run against other projects by passing the `PROJECT_ID` as an argument or environment variable.

## 4. Acceptance Criteria
*   [ ] `bin/run-benjamin-discovery.py` exists and executes successfully inside the Attila Docker container.
*   [ ] `sre-next_resources_v3.json` is generated with correct resource metadata and audit flags.
*   [ ] `2026-07-02-discovery_v3.md` is generated with the audit summary and detailed metadata.
*   [ ] The comparison section is added to the v3 report.
*   [ ] A GitHub Issue is successfully created (or drafted if CLI fails) tracking the SRE extension enhancement.
