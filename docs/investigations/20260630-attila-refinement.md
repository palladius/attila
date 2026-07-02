# Investigation: Project A.TT.I.L.A. Refinement
**Date:** 2026-06-30
**Buganizer ID:** [b/528279164](https://b.corp.google.com/issues/528279164)

## Context & Objectives

The goal is to create a stateful SRE investigation agent on GCP, consisting of two main parts:
1. **`attila`**: A setup CLI tool that configures the GCP infrastructure (GCS buckets, restricted Service Account, restricted Gemini API Key, Pub/Sub topics) using Terraform.
2. **`spapparo`**: An agent instance running inside a Docker container, with access to a GCS-backed sticky memory folder and GCP MCP tools (`safe_gcloud_exec`, `bq_gsql_exec`, `promql_exec`).

### Target for v0.2 (EOD June 30)
1. **Terraform**: Working configuration for project `sre-next` under user `ricc@gcp.altostrat.com`.
2. **Docker & Harness**: A local Docker container that runs the harness to perform discovery on `sre-next`.
3. **Sticky Memory**: Discovery results are saved in a sticky `memory/` directory (mounted or synced to GCS).

---

## Design Choices to Refine

To achieve the v0.2 PoC quickly today, we need to resolve a few key architectural questions:

### 1. Storage Implementation (`--storage <local|gcs>`)
To allow rapid local iteration, we will support a `--storage` flag with two modes:
* **`local` (v0.1 Target)**: The Docker container mounts a local host directory (e.g., `./memory/`) using a standard Docker bind mount. No GCS dependency.
* **`gcs` (v0.2/v0.3 Target)**: The container mounts a GCS bucket. We will support:
  * *Option A (gcsfuse):* Mount the GCS bucket directly inside the container using `gcsfuse` (requires `--cap-add SYS_ADMIN --device /dev/fuse`).
  * *Option B (Sync):* Bidirectional sync between a local mount and GCS at start/exit.

We will start with `--storage local` for v0.1 to get the agent logic working by EOD.

### 2. Harness Selection
What agent harness should we use for `spapparo`?
* **Approach A (Python ADK Agent)**: A bespoke Python agent built using Google's Agent Development Kit.
  * *Pros:* Fully supported, structured tool definitions, easy integration with custom MCPs.
  * *Cons:* Requires writing some boilerplate Python.
* **Approach B (Antigravity CLI - `agy`)**: Use the existing `agy` runner.
  * *Pros:* Zero boilerplate.
  * *Cons:* Doesn't natively support API keys easily.
* **Approach C (Bash / Python script + Gemini API)**: A lightweight custom script directly calling the Gemini API.
  * *Pros:* Ultra-lightweight, fast to build today.
  * *Cons:* We have to implement the tool-calling loop ourselves.

---

## Next Steps
1. Align with the user on the GCS mounting and Harness approach.
2. Draft the Terraform configuration for `attila`.
3. Create the Dockerfile and the discovery agent code.
