# Project A.TT.I.L.A. - Milestones & Feature Plan

This document maps the features of Project A.TT.I.L.A. to specific release milestones.

## Milestone 1: v0.1 - Local PoC (Today's Goal)
*Target Date: June 30, 2026*

The goal of v0.1 is to establish a working Proof of Concept (PoC) for a stateful SRE discovery agent using local storage.

### Features
*   **Harness**: `@google/gemini-cli` (npm package) running in non-interactive mode.
*   **Storage**: Local directory bind-mount (`memory/<PROJECT_ID>/`) on the host.
*   **Discovery Scope**: Read-only discovery of key GCP services:
    *   Compute & Serverless: GKE, Cloud Run, GCE.
    *   Networking & Security: VPC, IAM, Load Balancers.
*   **Outputs**:
    *   `DISCOVERY.md`: A markdown report summarizing active resources and findings.
    *   `architecture.json`: A machine-readable resource graph.
*   **Safety**: Execution governed by a restricted GCP Service Account (`safe-sre-investigator`) with `Viewer` role.
*   **Orchestration**: Simple Python CLI (`attila.py`) to initialize directories and run the Docker container.
*   **Automation**: `justfile` for building, running, and testing.

---

## Milestone 2: v0.2 - Cloud-State & ADK Integration
*Target Date: TBD*

The goal of v0.2 is to transition to a production-ready agentic framework with cloud-based state persistence.

### Features
*   **Harness**: Migrate from `gemini-cli` to the Python **Agent Development Kit (ADK)**.
*   **Storage**: Persistent state and memory stored in **GCS** (Google Cloud Storage) instead of local mounts, enabling team sharing.
*   **Troubleshooting**: Enable the agent to perform **Active Troubleshooting** (analyzing logs via Cloud Logging, metrics via Cloud Monitoring to diagnose issues).
*   **Tragedies**: Formalize incident tracking. Introduce **Tragedies** with unique **Tragedy IDs** and structured reports.
*   **Infrastructure**: Fully automated GCP resource provisioning via Terraform (Service Accounts, GCS Buckets, Pub/Sub).

---

## Milestone 3: v0.3 - Event-Driven & Mitigation
*Target Date: TBD*

The goal of v0.3 is to enable the agent to respond to events automatically and assist in resolving incidents.

### Features
*   **Triggers**: Event-driven execution. The agent is triggered by:
    *   Cloud Monitoring Alerts.
    *   Pub/Sub messages.
*   **Guided Mitigation**: The agent can suggest specific mitigation steps and, under human approval, execute them (e.g., restarting a service, scaling a deployment).
*   **Approval Flows**: Integrate Pub/Sub or Slack-based approval flows for mitigation actions.
