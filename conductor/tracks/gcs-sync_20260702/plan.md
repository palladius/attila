# Track Plan: Bi-directional GCS Backup and Sync

## Phase 1: Infrastructure Preparation
- [ ] Task: Verify GCS Bucket Terraform config
    - [ ] Check if `terraform/` templates correctly define `gs://PROJECT_ID-attila-public` and `gs://PROJECT_ID-attila-private` buckets.
    - [ ] Verify SA `safe-sre-investigator` has correct Storage Object Admin roles.
- [ ] Task: Conductor - User Manual Verification 'Phase 1'

## Phase 2: Implementation
- [ ] Task: Add GCS download to entrypoint
    - [ ] Modify `entrypoint.sh` to download files from GCS to `/app/memory` before launching the agent.
- [ ] Task: Add GCS upload/publish to entrypoint
    - [ ] Modify `entrypoint.sh` to rsync the local `/app/memory` back to the GCS private bucket on success.
    - [ ] Add step to publish final Markdown/HTML reports to the GCS public bucket.
- [ ] Task: Conductor - User Manual Verification 'Phase 2'

## Phase 3: Testing & E2E Validation
- [ ] Task: Validate sync inside container
    - [ ] Run test discovery and verify that files are successfully written to GCS buckets.
    - [ ] Verify that second runs pull historical state correctly.
- [ ] Task: Conductor - User Manual Verification 'Phase 3'
