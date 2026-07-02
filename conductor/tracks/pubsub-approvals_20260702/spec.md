# Track Specification: Pub/Sub and Approvals Flow

## Overview
A.TT.I.L.A. needs to support event-driven triggers and human-in-the-loop approvals for non-safe commands (mutating actions like drains, restarts, or config updates). This will be achieved using GCP Pub/Sub topics.

## Functional Requirements
1. **Pub/Sub Communication Topics**:
   - Establish topics for inbound triggers (alerts, tickets) and outbound notifications (investigation reports, approval requests).
2. **Approval Request Flow**:
   - When the agent proposes a mutating command, it must publish an approval request to the project's approvals topic.
   - The payload schema must contain:
     - The proposed command.
     - A Risk Factor metric (e.g. Red, Yellow, Green status).
     - Justification/Purpose of the command.
3. **Execution Block & Resume**:
   - The agent blocks execution on that task until it receives an approval message back on the project's inbound topic.

## Technical Design
- GCP Pub/Sub topics: `attila-triggers` and `attila-approvals`.
- JSON schemas for messaging format.
