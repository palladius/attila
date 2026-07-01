# LLM Specification: Project A.TT.I.L.A. (Flagello di Dio)

**Status:** DRAFT (Refined for v0.1 + test-config)
**Author:** Antigravity (LLM)
**Source Input:** [riccardo-specs.md](file:///usr/local/google/home/ricc/git/attila/docs/riccardo-specs.md)
**Buganizer ID:** [b/528279164](https://b.corp.google.com/issues/528279164)

> _"Ma che è 'sta roba? È la spada di Attila! Chi la impugna è il re dei re!"_ 🗡️ (Ungherese: Isten Kardja)

---

## 1. Overview & Phased Roadmap

Project A.TT.I.L.A. is a stateful SRE investigation tool on Google Cloud Platform (GCP). It enables Gemini-managed agents to retain memory and state across runs by leveraging a persistent storage layer.

To achieve a working PoC, we are executing a phased roadmap:

```
┌────────────────────────────────┐
│   v0.1 PoC                     │
│   - --storage local            │
│   - --harness geminicli        │
│   - Local bind mount           │
│   - Config validation          │
└───────────────┬────────────────┘
                │
                ▼
┌────────────────────────────────┐
│   v0.2+ Target                 │
│   - --storage gcs              │
│   - --harness adk              │
│   - Terraform infra setup      │
└────────────────────────────────┘
```

---

## 2. Architecture & Command-Line Interface

The project consists of two core components:

1. **`attila` (Setup CLI)**: Sets up the project directory, configures environment variables, validates configuration, and manages the orchestration.
2. **`spapparo` (Barbarian Harness)**: The agent execution container running the harness.

### Command-Line Interface

The `attila` CLI will support the following options:

```bash
attila init --project-id <PROJECT_ID> [--storage <local|gcs>]
attila run --project-id <PROJECT_ID> [--harness <geminicli|adk>] [--storage <local|gcs>]
attila test-config <config_file>
```

- **`--storage`**: Defaults to `local` in v0.1. Can be set to `gcs` in v0.2+.
- **`--harness`**: Defaults to `geminicli` in v0.1. Can be set to `adk` in v0.2+.
- **`test-config`**: Validates the GCP and LLM configuration using the specified config file (e.g., `.env`).

---

## 3. Storage & Directory Layout (v0.1: `--storage local`)

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
│       │   └── 2026-06-30.md
│       └── rules/                # Custom prompt rules
│           ├── 10-org.md
│           ├── 20-team.md
│           └── 30-user.md
├── Dockerfile
├── justfile
└── .env
```

### Docker Volume Mounts

When running the `spapparo` container, the following mounts are required:

- **Memory:** `-v $(pwd)/memory/<PROJECT_ID>:/memory`
- **GCP Credentials:** `-v $HOME/.config/gcloud/application_default_credentials.json:/adc.json:ro`

### Container Authentication & Setup (Entrypoint)

On startup, the container's entrypoint script will:
1. Authenticate `gcloud` using the mounted credentials and set the active account:
   ```bash
   gcloud config set project $PROJECT_ID
   gcloud config set auth/impersonate_service_account "safe-sre-investigator@$PROJECT_ID.iam.gserviceaccount.com"
   ```
   This ensures any direct `gcloud` execution inside the container is governed by the `safe-sre-investigator` IAM roles.
2. Install required Gemini extensions:
   ```bash
   gemini extensions install https://github.com/gemini-cli-extensions/sre
   ```

---

## 4. Harness Execution (v0.1: `--harness geminicli`)

In v0.1, the container runs the `@google/gemini-cli` tool as the agent harness using its non-interactive prompt mode.

### Execution Flow

1. The container starts and completes the authentication and extension setup.
2. It constructs the prompt, combining the user rules from `/memory/rules/` and the system instructions.
3. It executes the `gemini` command:
   ```bash
   gemini -p "Perform a GCP discovery of the project $PROJECT_ID. Write your findings to /memory/discovery/$(date +%Y-%m-%d)-discovery.md and the resource graph to /memory/architecture.json"
   ```
4. The output is written directly to the mounted `/memory/` directory.

---

## 5. Evals & Testing Framework

Evals are critical for validating agent behavior. They are kept separate from standard unit tests.

### Configurable Global Threshold

The evaluation framework uses a global success threshold instead of configuring it per test case.

- **Global Config:** `min_score: 0.7` (70% matching score). Can be overridden via environment variables (`ATTILA_EVAL_MIN_SCORE`) or CLI flags.

### Test Commands

- **`just test`**: Runs fast, local unit tests (e.g., verifying `attila` CLI config generation).
- **`just test-all`**: Runs the full suite, including the LLM-judged agentic evaluations.

### Eval Dataset Schema (`tests/evals.yaml`)

```yaml
global:
  min_score: 0.7

tests:
  - name: "GCP Discovery Test"
    description: "Verify the agent finds all active GCS buckets."
    prompt: "Discover the GCS buckets in the project."
    expected_findings:
      - "gs://sre-next-attila-public"
      - "gs://sre-next-attila-private"
```

---

## 6. Style & Tone

- **Diego Abatantuono Quotes:** The CLI output and help screens must feature quotes from _Attila Flagello di Dio_ (e.g., _"A come atroce, T come terremoto..."_).
- **Visuals:** Use terminal colors, rich emojis, and clear Mermaid/Excalidraw diagrams in documentation.

---

## 7. Configuration Testing (`test-config`)

To verify the setup and bypass potential organizational policy or permission blocks, `attila` provides a diagnostic command:

```bash
attila test-config <config_file>
```

This command runs a series of checks in order of execution speed (fastest/local first) to fail fast:

1.  **Local Environment Validation**:
    *   Verifies the config file (e.g., `.env`) exists.
    *   Checks that all required variables are populated (`PROJECT_ID`, `GCP_IDENTITY`, `GEMINI_API_KEY`).
2.  **GCP Project & Billing Status**:
    *   Runs `gcloud projects describe $PROJECT_ID` to verify project existence.
    *   Runs `gcloud beta billing projects describe $PROJECT_ID` to confirm billing is active.
3.  **Service Account Existence**:
    *   Verifies the `safe-sre-investigator@$PROJECT_ID.iam.gserviceaccount.com` service account exists.
4.  **GCS Buckets Verification**:
    *   Checks if `gs://$PROJECT_ID-attila-public` and `gs://$PROJECT_ID-attila-private` exist and are accessible.
5.  **Service Account Impersonation**:
    *   Verifies the current user (`GCP_IDENTITY`) can successfully impersonate the service account.
    *   Command: `gcloud --impersonate-service-account=safe-sre-investigator@$PROJECT_ID.iam.gserviceaccount.com auth print-access-token`
6.  **Gemini API Key Verification**:
    *   Runs a basic curl or LLM request using the configured `GEMINI_API_KEY` to ensure it is valid and has Gemini access.
7.  **Harness Execution & Authentication**:
    *   Verifies that the Docker container can be launched and that the internal `gemini-cli` or agent harness can authenticate correctly.
8.  **End-to-End Discovery Test**:
    *   Triggers a minimal discovery task (e.g., listing GCS buckets via the harness) and verifies the output is successfully written to the local `/memory` directory.

---

## 8. Use Cases

### UC01: Docker-As-An-Agent (CLI Wrapper)

A `docker run` execution should, by default, act as the agent execution itself.

**Is this a good idea?**
Yes, but only if implemented with **flexible delegation**:

1.  **Bake, Don't Fetch**: Pre-install the Gemini SRE extension and all dependencies during the `docker build` phase. Running `gemini extensions install` on every startup is too slow and depends on network availability.
2.  **Pass-Through Execution**: The entrypoint should set up the GCP credentials/impersonation and then check if arguments were passed:
    *   *No arguments:* Execute the default discovery/investigation agent (`exec gemini -y -p "$PROMPT"`).
    *   *Arguments passed:* Execute the arguments directly (e.g., `docker run attila:v0.1.0 bash` or `docker run attila:v0.1.0 gcloud storage ls`). This preserves debuggability.
3.  **State Isolation**: All agent state must be written to `/memory`, which is mounted from the host. The container itself remains stateless and disposable.

