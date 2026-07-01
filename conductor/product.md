# Project A.TT.I.L.A. (Flagello di Dio) - Product Guide

## 1. Vision & Value Proposition
Project A.TT.I.L.A. is a stateful SRE (Site Reliability Engineering) investigation agent designed to automate GCP discovery and diagnose infrastructure incidents. By maintaining state and memory across executions, A.TT.I.L.A. provides continuous context, allowing it to act as an intelligent assistant for complex cloud environments.

## 2. Target Users
*   **SRE & DevOps Engineers**: Leverage the agent to automate tedious GCP discovery tasks, map resource dependencies, and quickly diagnose active incidents.
*   **Cloud Architects**: Use the agent's generated resource graphs and documentation to visualize, audit, and maintain the architecture of GCP deployments.

## 3. Core Capabilities
*   **Active Troubleshooting**: Beyond simple resource listing, the agent analyzes logs, metrics, and configurations to diagnose active SRE incidents and identify root causes.
*   **Stateful Memory**: Retains context (resource graphs, previous findings, rules) across runs, enabling incremental analysis and avoiding redundant work.

## 4. Target GCP Services
The agent prioritizes discovery and troubleshooting in the following areas:
*   **Compute & Serverless**: GKE Clusters, Cloud Run Services, and GCE Instances.
*   **Networking & Security**: VPCs, IAM Roles/Permissions, and Load Balancers.

## 5. Operational Model & Execution
A.TT.I.L.A. is designed to be flexible and supports multiple execution triggers:
*   **Manual CLI/Docker Run**: Triggered ad-hoc by engineers during active incident response or manual audits.
*   **Scheduled/Continuous**: Runs periodically (e.g., cron) to update the resource graph and maintain an up-to-date state of the infrastructure.
*   **Event-Driven**: Triggered automatically by alerts from Cloud Monitoring or Pub/Sub events to initiate immediate diagnostic sweeps.

## 6. Roadmap & Version Mapping

### v0.1 (Today - PoC)
*   **Harness**: `@google/gemini-cli` (non-interactive).
*   **Storage**: Local directory bind-mounted (`memory/<PROJECT_ID>`).
*   **Core Feature**: Read-only GCP Discovery (focusing on GKE, Cloud Run, GCE, VPC, IAM).
*   **Output**: Markdown discovery report (`DISCOVERY.md`) and JSON resource graph (`architecture.json`).
*   **Infrastructure**: Manual/Local Docker execution, initial Terraform validation.

### v0.2 (Next Version)
*   **Harness**: Transition to Python **ADK** (Agent Development Kit).
*   **Storage**: Persistent state in **GCS** (Google Cloud Storage) for shared team memory.
*   **Core Feature**: Active Troubleshooting (analyzing logs/metrics to diagnose SRE incidents).
*   **Tragedies**: Introduce formal "Tragedy" tracking and Tragedy IDs.
*   **Infrastructure**: Full Terraform provisioning (Service Accounts, GCS buckets) in the `terraform/` subfolder.

### v0.3+ (Future)
*   **Core Feature**: Guided Mitigation (suggesting and executing fixes under human supervision).
*   **Execution**: Event-driven triggers (Cloud Monitoring alerts, Pub/Sub).
