#!/bin/bash
# A.TT.I.L.A. Discovery Runner (Wrapper)
# Co-authored by Jetski
#
# Usage: ./bin/run-discovery.sh [prompt] [env_file]

set -euo pipefail

PROMPT="${1:-}"
ENV_FILE="${2:-.env}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Forward to the generic runner by setting AGENT_PROMPT in the env
AGENT_PROMPT="$PROMPT" exec "$SCRIPT_DIR/docker-run.sh" "$ENV_FILE"
