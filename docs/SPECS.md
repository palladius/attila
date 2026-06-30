# LLM Specification: Project A.TT.I.L.A. (Flagello di Dio)

**Status:** DRAFT (Refined for v0.1)
**Author:** Antigravity (LLM)
**Source Input:** [riccardo-specs.md](file:///usr/local/google/home/ricc/git/ricclife-with-gemini-pvt/work/bugs/b528279164-attila/docs/SPECS/riccardo-specs.md)
**Buganizer ID:** [b/528279164](https://b.corp.google.com/issues/528279164)

> _"Ma che è 'sta roba? È la spada di Attila! Chi la impugna è il re dei re!"_ 🗡️ (Ungherese: Isten Kardja)

---

## 1. Overview & Phased Roadmap

Project A.TT.I.L.A. is a stateful SRE investigation tool on Google Cloud Platform (GCP). It enables Gemini-managed agents to retain memory and state across runs by leveraging a persistent storage layer.

To achieve a working PoC by End of Day (EOD) June 30, we are executing a phased roadmap:

```
┌────────────────────────────────┐
│   v0.1 PoC (EOD June 30)       │
│   - --storage local            │
│   - --harness geminicli        │
│   - Local bind mount           │
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

1. **`attila` (Setup CLI)**: Sets up the project directory, configures environment variables, and manages the orchestration.
2. **`spapparo` (Barbarian Harness)**: The agent execution container running the harness.

### Command-Line Interface

The `attila` CLI will support the following options:

```bash
attila init --project-id <PROJECT_ID> [--storage <local|gcs>]
attila run --project-id <PROJECT_ID> [--harness <geminicli|adk>] [--storage <local|gcs>]
```

- **`--storage`**: Defaults to `local` in v0.1. Can be set to `gcs` in v0.2+.
- **`--harness`**: Defaults to `geminicli` in v0.1. Can be set to `adk` in v0.2+.

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
- **GCP Service Account Key:** `-v ~/git/gemini-cli-tools/tools/gcp/service-account-key.json:/etc/gcp/sa-key.json:ro`

### Container Authentication & Setup (Entrypoint)

On startup, the container's entrypoint script will:
1. Authenticate `gcloud` using the mounted restricted service account key:
   ```bash
   gcloud auth activate-service-account safe-sre-investigator@$PROJECT_ID.iam.gserviceaccount.com --key-file=/etc/gcp/sa-key.json
   gcloud config set project $PROJECT_ID
   export GOOGLE_APPLICATION_CREDENTIALS=/etc/gcp/sa-key.json
   ```
   This ensures any direct `gcloud` execution inside the container is governed by the `safe-sre-investigator` IAM roles (e.g., `Viewer` role allows `gcloud compute instances list` but blocks `delete`/`create`).
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
