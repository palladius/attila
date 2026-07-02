# Track Plan: Observability and Cost Logging

## Phase 1: Setup Log Aggregation
- [ ] Task: Configure Docker Logging output
    - [ ] Update Dockerfile/entrypoint to ensure stderr/stdout are captured in a structured format.
    - [ ] Create `/app/memory/logs/` directory schema.
- [ ] Task: Conductor - User Manual Verification 'Phase 1'

## Phase 2: Implementation of Cost & Token Tracker
- [ ] Task: Integrate Token and API Cost calculator
    - [ ] Parse Gemini API response metadata for input/output token counts.
    - [ ] Add calculator utility that converts tokens to USD estimates based on current pricing models.
    - [ ] Append token/cost summaries to `memory/<PROJECT_ID>/reports/execution_costs.json`.
- [ ] Task: Conductor - User Manual Verification 'Phase 2'

## Phase 3: OpenTelemetry & Cloud Logs
- [ ] Task: Add OpenTelemetry tracing
    - [ ] Initialize OTEL SDK inside Python CLI/Harness scripts.
    - [ ] Instrument `safe_gcloud` execution hooks to measure crawler latencies.
- [ ] Task: Conductor - User Manual Verification 'Phase 3'
