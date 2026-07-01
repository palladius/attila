# Track Spec: Verify and Run Terraform Infrastructure

## 1. Objective
The objective of this track is to verify the existing Terraform configuration in the `terraform/` directory, ensure it is secure and correct, and execute it to provision the necessary GCP resources for Project A.TT.I.L.A. This includes setting up a Service Account with the `safe-sre-investigator` role and retrieving the Gemini API key.

## 2. Requirements
*   **Location**: All Terraform files must remain in the `terraform/` subfolder.
*   **Validation**: Must pass `terraform validate` and `terraform plan`.
*   **Execution**: Must be executed via the `just setup-infra sre-next` command to ensure the helper scripts and environment updates run correctly.
*   **Credentials**:
    *   Extract the Service Account private key to `credentials.json` in the project root.
    *   Retrieve the Gemini API key and update the `GEMINI_API_KEY` in the `.env` file.
*   **Safety**: Ensure the Service Account has read-only/viewer access to GCP resources to prevent accidental modifications during SRE investigations.

## 3. Success Criteria
*   `terraform/` configuration is validated.
*   `just setup-infra sre-next` completes successfully.
*   `credentials.json` exists in the root and contains a valid GCP service account key.
*   `.env` contains the correct `PROJECT_ID` and a non-empty `GEMINI_API_KEY`.
