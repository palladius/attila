# Implementation Plan: Track - Benjamin-Style GCP Discovery (v3)

## Phase 1: Scaffolding & Setup
- [ ] **Task: Create Discovery Script**
    - [ ] Create `bin/run-benjamin-discovery.py` in the repository root.
    - [ ] Set up basic argument parsing for `--project` (defaulting to `sre-next` or reading from env).
    - [ ] Set up logging and error handling.

## Phase 2: Implement Discovery & Audit Logic
- [ ] **Task: Implement Service Crawlers**
    - [ ] **GCE VMs:** Call `gcloud compute instances list`, filter GKE/Dataproc, check for public IPs.
    - [ ] **Cloud Run:** Call `gcloud run services list`, fetch IAM policy for each, check for `allUsers` invoker.
    - [ ] **GKE Clusters:** Call `gcloud container clusters list`, check `privateClusterConfig.enablePrivateEndpoint`.
    - [ ] **Cloud SQL:** Call `gcloud sql instances list`, check `ipConfiguration.ipv4Enabled` and `authorizedNetworks`.
    - [ ] **GCS Buckets:** Call `gcloud storage buckets list`, check `public_access_prevention`.
    - [ ] **VPC Networks:** Call `gcloud compute networks list`, check if `default` or `autoCreateSubnetworks` is true.

## Phase 3: Output Generation
- [ ] **Task: Write Output Files**
    - [ ] Format and write the JSON catalog to `/app/memory/discovery/sre-next_resources_v3.json`.
    - [ ] Format and write the Markdown Wiki report to `/app/memory/discovery/<date>-discovery_v3.md`.
    - [ ] Ensure the Markdown report contains the Executive Summary, Summary Table, and Detailed Metadata sections.

## Phase 4: Execution & Verification
- [ ] **Task: Run Discovery in Docker**
    - [ ] Build the Docker container: `just docker-build`.
    - [ ] Run the discovery using the custom script inside the container (via `bin/run-discovery.sh` or direct `docker run`).
    - [ ] Verify that the output files are correctly generated in `memory/sre-next/discovery/` on the host.

## Phase 5: Comparison & GHI
- [ ] **Task: Manual Comparison**
    - [ ] Read `memory/sre-next/discovery/2026-07-01-discovery-v1-vanilla.md` and `2026-07-01-discovery-v2-skill.md`.
    - [ ] Compare the findings with the new v3 report.
    - [ ] Append the "## Version Comparison (v1 vs v2 vs v3)" section to the v3 report.
- [ ] **Task: Create GitHub Issue**
    - [ ] Draft a GHI tracking the enhancement of the SRE extension based on these findings.
    - [ ] Attempt to create the issue using `gh` CLI: `gh issue create --title "..." --body "..."`. (Fallback to manual if CLI fails).
