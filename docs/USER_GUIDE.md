# Attila User Guide: Getting Started

Welcome to **Attila**, a containerized harness for running the **Gemini CLI** equipped with the **SRE Extension** in a secure, pre-configured environment.

This guide will help you set up the project, run the container, and troubleshoot common issues.

---

## Prerequisites

Before you begin, ensure you have the following installed on your host machine:
1.  **Docker**
2.  **gcloud CLI** (authenticated)
3.  **just** (optional, but highly recommended as a command runner)

---

## 1. Setup & Installation

### Step 1: Clone the Repository
```bash
git clone https://github.com/palladius/attila.git
cd attila
```

### Step 2: Configure the Environment
Copy the distribution template to create your local `.env` file:
```bash
cp .env.dist .env
```
Open `.env` and configure the following variables:
*   `PROJECT_ID`: Your target Google Cloud project (e.g., `sre-next`).
*   `GCP_IDENTITY`: Your active GCP email (e.g., `your-name@gcp.altostrat.com` or `your-name@gmail.com`).
    > [!IMPORTANT]
    > **Bypassing CAA Blocks:** Do NOT use your main `@google.com` corp account here. Google Corp accounts are blocked inside Docker by Context-Aware Access (CAA). Use an alternative identity (like Altostrat or a personal Gmail) that you have authenticated on your host.

### Step 3: Authenticate on the Host
The container mounts your host's gcloud credentials. You must authenticate the target `GCP_IDENTITY` on your host at least once before running the container:
```bash
# 1. Login with your target identity
gcloud auth login your-name@gcp.altostrat.com

# 2. Generate Application Default Credentials (ADC)
gcloud auth application-default login
```

### Step 4: Build the Docker Image
Build the pre-configured image (which contains Gemini CLI v0.49.0 and the SRE extension pre-installed):
```bash
just docker-build
```
*(If you don't have `just`, run: `docker build -t attila:v0.2.0 .`)*

---

## 2. How to Invoke

Attila provides a generic runner that mounts your host's credentials and workspace.

### Option A: Interactive Bash Shell (Recommended for exploring)
To start the container and drop into a `bash` session:
```bash
just docker-run
```
Once inside the container, you can run `gemini` interactively:
```bash
root@container:/app# gemini
```
It will automatically authenticate using Vertex AI and start the session.

### Option B: Run a One-Off Command
You can pass any command directly to the runner:
```bash
# Check which project the container is pointing to
just docker-run .env gcloud config get-value project

# Run a single prompt via Gemini CLI (headless mode)
just docker-run .env gemini -p "List my GCS buckets"
```

### Option C: Run SRE Resource Discovery
To run the automated SRE discovery agent which scans your project and generates an architecture report:
```bash
just run-discovery
```
This runs the discovery skill and writes the output files to your host's `memory/` directory.

---

## 3. Expected Outcomes

### On Successful Startup (`just docker-run`)
You should see the barbarian startup banner confirming your identities:
```
====================================================
🗡️  Spapparo Barbarian Agent starting up...
====================================================
🟢 PROJECT ID: sre-next
🟢 HOST IDENTITY: your-name@gcp.altostrat.com
🟢 IMPERSONATING: safe-sre-investigator@sre-next.iam.gserviceaccount.com
====================================================
[+] Configuring SDK with mounted ADC...
[+] Setting active gcloud account to: your-name@gcp.altostrat.com
...
[+] Successfully impersonating safe-sre-investigator@sre-next.iam.gserviceaccount.com
[+] Creating safe_gcloud wrapper...
[+] Executing custom command inside container: bash
----------------------------------------------------
root@container:/app#
```

### On Successful Discovery (`just run-discovery`)
The script will run the SRE agent and write the following files to your host:
*   `memory/sre-next/architecture.json`: A raw JSON graph of your GCP resources.
*   `memory/sre-next/discovery/`: A directory containing markdown reports summarizing the discovered resources, service accounts, and SRE risks.

---

## 4. Possible Issues & Troubleshooting

### 1. `ModelNotFoundError` for `gemini-3.5-flash`
*   **Symptom:** When running a headless prompt (e.g., `gemini -p "..."`), it fails with:
    `ModelNotFoundError: Publisher model ... gemini-3.5-flash was not found...`
*   **Reason:** The Gemini CLI v0.49.0 defaults to `gemini-3.5-flash` for agent turns. If your GCP project does not yet have access to this model in its region, the API call fails.
*   **Workaround:**
    1.  Use **interactive mode** (`gemini` without `-p`), which automatically detects the error and falls back to an available model (like `gemini-3.1-pro-preview`).
    2.  Ask your project administrator to enable `gemini-3.5-flash` in Vertex AI.

### 2. `Permission Denied` / CAA Blocks
*   **Symptom:** `gcloud` commands inside the container fail with authentication or block errors.
*   **Reason:** You are likely using your `@google.com` corp account.
*   **Fix:** Re-run `gcloud auth login` on the host with your Altostrat or personal account, update `GCP_IDENTITY` in `.env`, and restart the container.

### 3. `Failed to load API key from storage` / Corrupted Credentials
*   **Symptom:** You see a warning about a corrupted `gemini-credentials.json` file.
*   **Reason:** This is a common warning when switching environments or when the mounted config directory has legacy files.
*   **Fix:** You can safely ignore this warning as long as the Vertex AI authentication succeeds.
