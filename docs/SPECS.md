# Project A.TT.I.L.A. Specification - v2.0 (Evolved PoC)

**Status:** APPROVED / ACTIVE  
**Author:** Antigravity (LLM)  
**Source Input:** [riccardo-specs.md](file:///usr/local/google/home/ricc/git/attila/docs/riccardo-specs.md)  
**Target Version:** v0.2  
**Buganizer ID:** [b/528279164](https://b.corp.google.com/issues/528279164)

> _"Ma che è 'sta roba? È la spada di Attila! Chi la impugna è il re dei re!"_ 🗡️ (Ungherese: Isten Kardja)

---

## 1. Executive Summary & Evolved Architecture

Project A.TT.I.L.A. has evolved from a single-project PoC into a **multi-environment, containerized SRE agent runner**. It allows an operator (SRE) to securely run Gemini-powered discovery and investigation agents against multiple GCP environments (e.g., personal sandbox, team projects, enterprise orgs) with zero-trust local execution.

```mermaid
graph TD
    Host[Host Machine] -->|1. Swaps Config| Env[".env.altostrat / .env.pbt"]
    Host -->|2. Runs Validator| Val["bin/test-config.sh"]
    Val -->|3. Verifies Host| HostGcp["Host gcloud / PubSub / GCS"]
    Val -->|4. Verifies Container| Docker["Docker Container (attila:v0.1.0)"]
    Docker -->|5. Runs Agent| Gemini["Gemini CLI + SRE Extension"]
    Gemini -->|6. Discovers Resources| GCP["Target GCP Project (sre-next / etc.)"]
    Gemini -->|7. Writes Report| Mount["/app/memory (Mounted to Host)"]
    Mount -->|8. Persists| HostMem["host: memory/<PROJECT_ID>/"]
```

---

## 2. Command-Line Interface

The `attila` CLI supports the following options:

```bash
attila init --project-id <PROJECT_ID> [--storage <local|gcs>]
attila run --project-id <PROJECT_ID> [--harness <geminicli|adk>] [--storage <local|gcs>]
attila test-config <config_file>
```

*   **`--storage`**: Defaults to `local` in v0.1. Can be set to `gcs` in v0.2+.
*   **`--harness`**: Defaults to `geminicli` in v0.1. Can be set to `adk` in v0.2+.
*   **`test-config`**: Validates the GCP and LLM configuration using the specified config file (e.g., `.env`).

---

## 3. Storage & Directory Layout

In `local` storage mode, the agent's memory is persisted in a local directory on the host machine and mounted into the Docker container.

### Directory Structure on Host

```
~/git/attila/
├── memory/
│   └── <PROJECT_ID>/
│       ├── DISCOVERY.md          # Latest high-level GCP map
│       ├── ARCHITECTURE.md       # Human-readable architecture notes
│       ├── architecture.json     # Machine-readable resource graph
│       ├── discovery/            # Timestamped discovery logs
│       │   └── YYYY-MM-DD-discovery.md
│       └── rules/                # Custom prompt rules
│           ├── 10-org.md
│           ├── 20-team.md
│           └── 30-user.md
├── Dockerfile
├── justfile
└── .env
```

---

## 4. Scenario Workflows

### Phase 1: Fast Configuration Validation (`test-config`)
Before launching a long-running agent, the operator must ensure the environment is fully functional.

1.  **Trigger**: The operator runs:
    ```bash
    just test-config .env.altostrat
    ```
2.  **Execution**: The 8-step validator ([bin/test-config.sh](file:///usr/local/google/home/ricc/git/attila/bin/test-config.sh)) executes:
    *   **Steps 1-3 (Host-side Metadata)**: Verifies the Service Account exists, Vertex AI API is enabled, and required GCS/PubSub resources exist.
    *   **Step 4 (Host-side Impersonation)**: Verifies the operator can impersonate the SA on the host.
    *   **Step 5 (API Key)**: Verifies the Gemini API key (if configured).
    *   **Step 6 (Container-side gcloud)**: Launches the container, mounts the host's `gcloud` credentials, and verifies that `gcloud` inside the container can list buckets using SA impersonation (capped with a 30s timeout).
    *   **Step 7 (Container-side Gemini)**: Runs a cheap Gemini query inside the container E2E to verify Vertex AI access.
    *   **Step 8 (Container-side E2E)**: Asks Gemini inside the container to list buckets, verifying the agent's tool-use capability.

---

### Phase 2: Autonomous Resource Discovery

Once validated, the operator launches the discovery agent.

1.  **Trigger**: The operator runs:
    ```bash
    just run-discovery "" .env.altostrat
    ```
2.  **Container Initialization**:
    *   The host's `memory/sre-next/` directory is mounted to `/app/memory` in the container.
    *   The container's [entrypoint.sh](file:///usr/local/google/home/ricc/git/attila/entrypoint.sh) starts, configures `gcloud` to impersonate the SA, and uses the pre-installed Gemini SRE extension.
    *   The entrypoint creates a `safe_gcloud` wrapper to satisfy the SRE extension's requirement for safe execution.
3.  **Agent Execution (YOLO Mode)**:
    *   The Gemini CLI starts in YOLO mode (`-y`), automatically approving all tool calls.
    *   The agent uses `gcloud` (via the wrapper) to query GCS, Compute Engine, GKE, Cloud SQL, Cloud Run, Pub/Sub, and Cloud Functions.
4.  **Secure Report Persistence**:
    *   The agent compiles its findings.
    *   It writes the Markdown report to `/app/memory/discovery/YYYY-MM-DD-discovery.md` and the resource graph to `/app/memory/architecture.json`.
    *   Since `/app` is the container's working directory, `/app/memory` is trusted by the Gemini CLI security policy, allowing the write to succeed.

---

## 5. Use Cases

### UC01: Docker-As-An-Agent (CLI Wrapper)

A `docker run` execution should, by default, act as the agent execution itself.

**Is this a good idea?**
Yes, but only if implemented with **flexible delegation**:

1.  **Bake, Don't Fetch**: Pre-install the Gemini SRE extension and all dependencies during the `docker build` phase. Running `gemini extensions install` on every startup is too slow and depends on network availability.
2.  **Pass-Through Execution**: The entrypoint should set up the GCP credentials/impersonation and then check if arguments were passed:
    *   *No arguments:* Execute the default discovery/investigation agent (`exec gemini -y -p "$PROMPT"`).
    *   *Arguments passed:* Execute the arguments directly (e.g., `docker run attila:v0.1.0 bash` or `docker run attila:v0.1.0 gcloud storage ls`). This preserves debuggability.
3.  **State Isolation**: All agent state must be written to `/memory`, which is mounted from the host. The container itself remains stateless and disposable.

---

## 6. Architecture Decision Records (ADRs)

### ADR 001: `/app/memory` Mounting over Root `/memory`
*   **Context**: Gemini CLI restricts file writes to trusted workspace folders (defined in `trustedFolders.json`). Writing to a root-level `/memory` mount failed because the SRE extension restricted the active workspace.
*   **Decision**: Mount the host's memory directory to a subdirectory of the working directory (`/app/memory`). Since `/app` is the default trusted workspace, all subdirectories are implicitly trusted, resolving the write block without complex configuration.

### ADR 002: Container Argument Pass-Through
*   **Context**: The original entrypoint forced the default discovery prompt, preventing operators from running custom tasks or interactive shells.
*   **Decision**: Update `entrypoint.sh` to check for arguments (`$# -gt 0`). If present, it bypasses the default agent run and executes the arguments (e.g., `exec "$@"`). This enables running `bash` or `gemini` interactively.

### ADR 003: `safe_gcloud` Wrapper
*   **Context**: The SRE extension's `safe-sre-investigator` skill expects a `safe_gcloud` command to be present in the environment to prevent destructive actions.
*   **Decision**: Create a lightweight wrapper at `/usr/local/bin/safe_gcloud` in the container that simply forwards commands to `gcloud` (safely discarding the project ID argument which is already set globally).

---

## 7. Style & Tone

*   **Diego Abatantuono Quotes**: The CLI output and help screens must feature quotes from _Attila Flagello di Dio_ (e.g., _"A come atroce, T come terremoto..."_).
*   **Visuals**: Use terminal colors, rich emojis, and clear Mermaid/Excalidraw diagrams in documentation.
