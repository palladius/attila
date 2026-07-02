# Track Plan: Python ADK Harness Migration

## Phase 1: Environment & Scaffolding
- [ ] Task: Update Dockerfile for ADK
    - [ ] Install python packages required for ADK (`google-genai`, etc.).
    - [ ] Ensure python runtime dependencies are pre-baked during image build.
- [ ] Task: Conductor - User Manual Verification 'Phase 1'

## Phase 2: Tool Registry & Agent Definition
- [ ] Task: Port SRE Tools to ADK Format
    - [ ] Re-implement `safe_gcloud`, `bq_gsql_exec` as python functions registered with ADK `@tool` decorator.
- [ ] Task: Define the ADK Discovery Agent
    - [ ] Create agent scripts utilizing ADK `Agent` orchestration classes.
    - [ ] Integrate system instructions and task prompts from `workflow.md`.
- [ ] Task: Conductor - User Manual Verification 'Phase 2'

## Phase 3: Integration & Parity Testing
- [ ] Task: E2E Parity Check
    - [ ] Run the ADK discovery agent against `sre-next` target.
    - [ ] Compare output `architecture.json` and `DISCOVERY.md` with Node-based Gemini CLI results.
- [ ] Task: Conductor - User Manual Verification 'Phase 3'
