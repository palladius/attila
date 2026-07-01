# Project A.TT.I.L.A. - Development Workflow

This document outlines the standard development workflow for Project A.TT.I.L.A.

## 1. Spec-Driven Development (SDD)
We follow a strict Spec-Driven Development process managed by Conductor:
1.  **Define**: All features or bug fixes must start with a specification (e.g., in `docs/` or a Conductor Track Spec).
2.  **Plan**: Break down the specification into a task list (Track Plan) before writing code.
3.  **Implement**: Implement the changes incrementally.
4.  **Verify**: Verify the implementation against the plan and run tests.
5.  **Review**: Perform a code review before merging.

## 2. Code Changes & Git Protocol
*   **Branching**: Create short-lived feature branches from the main branch.
    *   Naming: `feature/<short-description>` or `bugfix/<bug-id>`.
*   **Commits**: Keep commits atomic and descriptive.
*   **CL/PR Tagging**:
    *   Always tag descriptions with `TAG=agy`.
    *   Include `CONV=<conversation_id>` if working with an AI assistant.

## 3. Verification & Testing
Before submitting any changes, you MUST run the following verification steps:
1.  **Code Quality**: Ensure code adheres to the style guides in `conductor/code_styleguides/`.
2.  **Infrastructure Verification**:
    *   If Terraform files are modified, validate them:
        ```bash
        cd terraform && terraform validate
        ```
3.  **Local Unit Tests**:
    *   Run fast local tests:
        ```bash
        just test
        ```
4.  **Agentic Evaluations (Evals)**:
    *   Run the full evaluation suite to ensure the agent's behavior has not regressed:
        ```bash
        just test-all
        ```
    *   Or run evals directly:
        ```bash
        python3 run_evals.py
        ```
5.  **Docker Build**:
    *   Verify the container builds successfully:
        ```bash
        just docker-build
        ```

## 4. Infrastructure Deployment
*   All Terraform code must reside in the `terraform/` directory.
*   **Authentication**: Terraform requires Application Default Credentials (ADC). If you encounter authentication errors (e.g., `invalid_grant` or `invalid_rapt`), run the helper command to log in:
    ```bash
    just attila-gcloud-login
    ```
*   To apply infrastructure changes and update the local environment:
    ```bash
    just setup-infra
    ```
    *Note: This will automatically update the `.env` file with the necessary keys (do NOT manually delete or alter `.env` except via this command).*
