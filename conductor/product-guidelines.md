# Project A.TT.I.L.A. - Product Guidelines

## 1. Tone & Voice
*   **Themed Professionalism**: All user-facing interactions (CLI output, logs, reports) should use a hybrid tone. The core SRE content must be technically accurate and professional, but wrapped in the "Attila the Hun" / "Barbarian" theme.
*   **Cinematic Flair**: Use bold emojis (e.g., 🗡️, 🔥, 🏰) and selective quotes from *Attila Flagello di Dio* (e.g., *"Sbabbari..."*) to add personality.
*   **No Clichés**: Avoid generic AI-sounding helpfulness. Be direct, slightly theatrical, but technically precise.

## 2. Documentation & Report Style (e.g., `DISCOVERY.md`, `TRAGEDY.md`)
*   **Visual & Structured**:
    *   Use Mermaid diagrams to visualize GCP resource relationships and network topologies.
    *   Use Markdown tables to list resources, costs, and status.
    *   Use bold highlights for critical findings.
*   **Raw & Verifiable**:
    *   Include relevant raw log snippets or `gcloud` command outputs to support findings.
    *   Provide verification commands so the user can easily reproduce the agent's findings.

## 3. Error Handling & "Tragedies"
*   **Dramatic Warnings**: Errors and warnings must be loud and dramatic. Use red terminal text, warning emojis, and thematic quotes.
*   **Incidents as Tragedies**:
    *   Active SRE incidents or critical failures are classified as **Tragedies**.
    *   Each Tragedy must be assigned a unique **Tragedy ID** (e.g., `TRAGEDY-YYYYMMDD-XXX`).
*   **Actionable Resolution**: Despite the drama, every error/Tragedy MUST provide:
    *   **Clear Mitigation Steps**: What the user or agent needs to do to resolve it.
    *   **Permalinks**: Links to relevant GCP Console pages, logs, or internal documentation (g3doc, runbooks).

## 4. Naming Conventions
*   **Technical Standard**: The codebase should generally use standard technical SRE and GCP terminology (avoid over-the-top branding in variable names, database schemas, etc.).
*   **Approved Thematic Exceptions**:
    *   The agent execution harness is named **`spapparo`**.
    *   Incidents and critical failures are named **`Tragedy`** (with `Tragedy ID`).
    *   State/Memory is referred to as **`Memory`** or **`State`** (do NOT use "saccheggio").
