# Project A.TT.I.L.A. - Technology Stack

## 1. Core Languages & Runtimes
*   **Python 3**: Primary language for the orchestration CLI (`attila.py`) and the evaluation framework (`run_evals.py`).
*   **Node.js**: The execution harness (`@google/gemini-cli`) runs on Node.js (v24).
*   **Bash**: Used for the Docker container entrypoint (`entrypoint.sh`) and lightweight automation scripts.

## 2. Agent Harness & Orchestration
*   **v0.1 (Current)**: `@google/gemini-cli` (npm package, run in non-interactive mode).
*   **v0.2+ (Target)**: Google **Agent Development Kit (ADK)** for Python, transitioning to a more structured agentic framework.

## 3. Infrastructure & Deployment
*   **Docker**: The agent execution environment (`spapparo`) is containerized using `node:24-bullseye` as the base, with Python and GCP CLI pre-installed.
*   **Terraform**: Used for provisioning GCP resources (Service Accounts, IAM roles, API keys). All Terraform code is strictly maintained in the `terraform/` subfolder.
*   **Just**: Command runner (`justfile`) used to simplify development workflows (building, running, testing).

## 4. Integration & APIs
*   **Gemini API**: Core LLM provider (requires `GEMINI_API_KEY`).
*   **Google Cloud SDK (gcloud)**: Used inside the container for resource discovery and authenticated SRE tasks.
