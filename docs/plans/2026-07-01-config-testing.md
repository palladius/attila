# Robust Configuration Swapping & Validation Plan

> **For Gemini:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Enable `attila` to swap between multiple GCP configurations (work vs personal) by supporting custom Application Default Credentials (ADC) files, and verify the setup using `attila test-config`.

**Architecture:** 
- Update `bin/run-discovery.sh` and `bin/test-config.sh` to support a `GCP_ADC_FILE` environment variable (defined in `.env`), falling back to a workspace-local path (`credentials/adc.json`) before defaulting to the global host ADC.
- Add validation to `cli/attila.py` to verify the configured `GCP_ADC_FILE` exists.
- Provide a sample multi-account configuration for testing.

**Tech Stack:** Bash, Python 3, Docker, gcloud CLI.

---

### Task 1: Support Custom ADC in `bin/run-discovery.sh`

**Files:**
- Modify: `bin/run-discovery.sh`

**Step 1: Implement custom ADC resolution logic**
Modify `bin/run-discovery.sh` to resolve `ADC_PATH` based on:
1. `GCP_ADC_FILE` from `.env` if set.
2. Local `./credentials/adc.json` if it exists.
3. Host's global `$HOME/.config/gcloud/application_default_credentials.json` as fallback.

```bash
# Resolve ADC path
if [ -n "${GCP_ADC_FILE:-}" ]; then
  ADC_PATH="$GCP_ADC_FILE"
elif [ -f "credentials/adc.json" ]; then
  ADC_PATH="credentials/adc.json"
else
  ADC_PATH="${USER_HOME}/.config/gcloud/application_default_credentials.json"
fi

echo "[+] Using ADC path: $ADC_PATH"
```

**Step 2: Run verification**
Run: `bash -n bin/run-discovery.sh`
Expected: Syntax is correct.

**Step 3: Commit**
```bash
git add bin/run-discovery.sh
git commit -m "feat: :key: support custom GCP_ADC_FILE in run-discovery.sh"
```

---

### Task 2: Support Custom ADC in `bin/test-config.sh`

**Files:**
- Modify: `bin/test-config.sh`

**Step 1: Implement the same ADC resolution logic in `test-config.sh`**
Replace the hardcoded `ADC_PATH` resolution (around line 163) with the multi-option resolution.

```bash
# Resolve ADC path
if [ -n "${GCP_ADC_FILE:-}" ]; then
  ADC_PATH="$GCP_ADC_FILE"
elif [ -f "credentials/adc.json" ]; then
  ADC_PATH="credentials/adc.json"
else
  ADC_PATH="${HOME}/.config/gcloud/application_default_credentials.json"
fi

if [ ! -f "$ADC_PATH" ]; then
  echo -e "  ${RED}✗ ADC file not found at $ADC_PATH. Run 'gcloud auth application-default login' or set GCP_ADC_FILE.${NC}"
  exit 1
fi
```

**Step 2: Run verification**
Run: `bash -n bin/test-config.sh`
Expected: Syntax is correct.

**Step 3: Commit**
```bash
git add bin/test-config.sh
git commit -m "feat: :key: support custom GCP_ADC_FILE in test-config.sh"
```

---

### Task 3: Validate `GCP_ADC_FILE` in `cli/attila.py`

**Files:**
- Modify: `cli/attila.py`

**Step 1: Add validation in `test_config` function**
Modify `test_config` to check if `GCP_ADC_FILE` is defined in the config file and verify the file exists on the host before executing the bash script.

```python
    # Read the config file to check for GCP_ADC_FILE
    if Path(config_file).exists():
        with open(config_file) as f:
            content = f.read()
            if "GCP_ADC_FILE" in content:
                # Extract path
                for line in content.splitlines():
                    if line.startswith("GCP_ADC_FILE="):
                        adc_path = line.split("=", 1)[1].strip("'\" ")
                        if adc_path and not Path(adc_path).exists():
                            print(f"\033[31m[-] Error: Configured GCP_ADC_FILE '{adc_path}' does not exist.\033[0m")
                            sys.exit(1)
```

**Step 2: Commit**
```bash
git add cli/attila.py
git commit -m "feat: :white_check_mark: validate GCP_ADC_FILE existence in attila CLI"
```

---

### Task 4: Create a Test Configuration for Verification

**Files:**
- Create: `tests/test_env.work`
- Create: `credentials/.gitkeep`

**Step 1: Create a test env file**
Create `tests/test_env.work` mimicking a work configuration:
```env
PROJECT_ID=sre-next
GCP_IDENTITY=ricc@gcp.altostrat.com
STORAGE_TYPE=local
HARNESS=geminicli
GEMINI_API_KEY=AIzaSyDummyKeyForTestingPurposes
GCP_ADC_FILE=credentials/work-adc.json
```

**Step 2: Create credentials folder**
Ensure the `credentials/` directory is created and ignored in `.gitignore` (except for a `.gitkeep` if we want to preserve the folder structure).

**Step 3: Commit**
```bash
git add tests/test_env.work
git commit -m "test: :wrench: add test config tests/test_env.work"
```

---

### Task 5: End-to-End Verification

**Files:**
- None (Execution and testing)

**Step 1: Build the docker image**
Run: `just docker-build`
Expected: Container builds successfully as `attila:v0.1.0`.

**Step 2: Run the config validator**
Run: `just test-config`
Expected: All 7 tests pass (or fail informatively if credentials are not set up).

**Step 3: Run with the test config**
Run: `just test-config tests/test_env.work`
Expected: Fails at Test 6/Test 7 if `credentials/work-adc.json` is missing, but passes if we copy the active credentials there.
