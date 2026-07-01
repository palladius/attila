# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.2.0] - 2026-07-01
### Added
- :goggles: **8-Step Config Validator**: Modernized `test-config.sh` with host/container emojis, Pub/Sub checks, and container-side E2E Gemini verification.
- :rocket: **Skip-on-Success Optimization**: Added `.ok` marker files to skip slow container tests if the configuration hasn't changed.
- :shield: **Enhanced SRE Security**: Pre-provisioned 13 specific SRE Viewer and BigQuery roles in `setup-infra.sh` and Terraform.
- :whale: **Interactive Container Mode**: Updated `entrypoint.sh` to support custom commands (e.g., `bash`, `gemini`) and created a `safe_gcloud` wrapper.
- :folder: **Workspace Mount Fix**: Mounted host memory to `/app/memory` to comply with Gemini CLI's trusted workspace policy.
- :memo: **Evolved Spec**: Added `SPECS-v2.md` with the SRE resource discovery use case.

### Changed
- Refactored `test-config.sh` to resolve the version dynamically from the `VERSION` file.

## [0.1.0] - 2026-06-30
### Added
- :tada: Initial repository setup.
- :memo: High-level spec and v0.1 PoC planning.
