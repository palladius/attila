# Track Specification: Bi-directional GCS Backup and Sync

## Overview
To enable persistent, shared team memory across stateless container executions, A.TT.I.L.A. needs to automatically sync its sticky `memory/` directory to Google Cloud Storage (GCS) at the start and end of every run.

## Functional Requirements
1. **Private Memory Sync**:
   - At startup, download existing memory from `gs://${PROJECT_ID}-attila-private/memory/` to the local `/app/memory/` directory.
   - At completion, upload any new/modified findings, incident reports, and architecture graphs back to `gs://${PROJECT_ID}-attila-private/memory/`.
2. **Public Report Publishing**:
   - Copy final HTML discovery and investigation reports to the public bucket `gs://${PROJECT_ID}-attila-public/` to allow easy sharing and viewing.
3. **Robustness**:
   - Handle cases where buckets do not exist (fail gracefully or create them on the fly if permissions allow).
   - Use atomic sync tools (like `gcloud storage rsync`) to minimize API calls and only sync modified files.

## Tech Stack & Tooling
- `gcloud storage rsync` (preferred CLI tool for high efficiency).
- Integration into the docker entrypoint (`entrypoint.sh`).
