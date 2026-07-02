# Track Specification: Python ADK Harness Migration

## Overview
Currently, A.TT.I.L.A. uses `@google/gemini-cli` (Node.js) for executing prompts and tool invocations. To support structured multi-agent collaboration, fine-grained validation checkpoints, and Python-native tool integration, we will transition to the Google Agent Development Kit (ADK) for Python.

## Functional Requirements
1. **ADK Agent Initialization**:
   - Initialize a python-native ADK agent within the container.
   - Configure credentials, models, and session management using ADK API patterns.
2. **Tool Porting**:
   - Register SRE Extension tools (`safe_gcloud_exec`, `bq_gsql_exec`, `promql_exec`) as ADK Python tools.
   - Preserve safe-execution checks inside Python tool wrappers.
3. **Structured Outputs**:
   - Ensure the ADK agent produces structured Markdown reports and JSON resource graphs matching the v0.1 format.

## Technology Stack
- Google Agent Development Kit (ADK) for Python.
- Python 3.10+.
- Vertex AI SDK for Gemini models.
