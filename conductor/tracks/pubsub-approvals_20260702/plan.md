# Track Plan: Pub/Sub and Approvals Flow

## Phase 1: Pub/Sub Topics Provisioning
- [ ] Task: Terraform Pub/Sub configuration
    - [ ] Add `google_pubsub_topic` definitions for `attila-triggers` and `attila-approvals` to `terraform/main.tf`.
    - [ ] Create pull/push subscriptions as required.
- [ ] Task: Conductor - User Manual Verification 'Phase 1'

## Phase 2: Implementation of Approvals Logic
- [ ] Task: Implement Command Proposer
    - [ ] Create agent functionality that identifies mutating actions and halts them.
    - [ ] Build JSON serializer to publish the approval payload (proposed command, risk factor, purpose).
- [ ] Task: Implement Polling/Wait Mechanism
    - [ ] Set up subscription listener to check for human approval response messages.
    - [ ] Write integration test validating approval message consumption.
- [ ] Task: Conductor - User Manual Verification 'Phase 2'
