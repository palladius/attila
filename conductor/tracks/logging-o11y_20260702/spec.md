# Track Specification: Observability and Cost Logging

## Overview
A.TT.I.L.A. needs robust observability to keep track of execution steps, diagnostic trace paths, API request/response logs, and model API costs (input/output tokens) per execution.

## Functional Requirements
1. **Token & Cost Tracking**:
   - Track LLM input and output token consumption for each agent invocation.
   - Aggregate total costs broken down by Gemini model called.
2. **Activity Logging**:
   - Persist execution logs for all harnesses running inside Docker.
   - Log files must be periodically synchronized or streamed to Google Cloud Logging or structured GCS files to prevent loss if a container exits abruptly.
3. **OpenTelemetry Integration**:
   - Implement OpenTelemetry tracing inside the agent's execution code.
   - Support tracing of external resource crawler calls (gcloud execution duration, SQL queries, etc.).

## Technical Design
- Use structured JSON logs for easy parsing.
- Integrate with Cloud Logging API or write local `/app/memory/logs/` files synced to GCS.
