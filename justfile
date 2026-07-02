# A.TT.I.L.A. Justfile
# "A come atroce, T come terremoto, T come tragedia, I come iradiddio..."

# Load .env file automatically
set dotenv-load := true

version := `cat VERSION`

# Print help by default
default:
	@just -f {{justfile()}} --list

# Authenticate gcloud and Application Default Credentials (ADC)
attila-gcloud-login:
	@echo "[+] Authenticating gcloud CLI..."
	gcloud auth login
	@echo "[+] Authenticating Application Default Credentials (ADC) for Terraform..."
	gcloud auth application-default login

# Initialize the workspace for a GCP project
init project_id:
	python3 cli/attila.py init --project-id {{project_id}}

# Set up the GCP infrastructure (default: terraform, optional: bash)
setup-infra method="terraform" env_file=".env":
	@if [ "{{method}}" = "terraform" ]; then \
		just setup-infra-tf "{{env_file}}"; \
	elif [ "{{method}}" = "bash" ]; then \
		just setup-infra-bash "{{env_file}}"; \
	else \
		echo "[-] ERROR: Invalid method. Use 'terraform' or 'bash'."; \
		exit 1; \
	fi

# Provision via Terraform
setup-infra-tf env_file=".env":
	@if [ ! -f "{{env_file}}" ]; then \
		echo "[-] ERROR: Env file {{env_file}} not found."; \
		exit 1; \
	fi
	@. {{env_file}}; \
	ACTIVE_IDENTITY=$(gcloud config get-value account 2>/dev/null); \
	if [ "$ACTIVE_IDENTITY" != "$GCP_IDENTITY" ]; then \
		echo "[-] ERROR: Identity mismatch!"; \
		echo "    Active gcloud account: $ACTIVE_IDENTITY"; \
		echo "    Required env account: $GCP_IDENTITY"; \
		echo "    Please run: gcloud config set account $GCP_IDENTITY"; \
		exit 1; \
	fi
	@echo "[+] Running Terraform Apply using {{env_file}}..."
	cd terraform && terraform apply -var="project_id=$PROJECT_ID" -var="gcp_identity=$GCP_IDENTITY" -auto-approve

# Provision via Bash Script (best-effort, bypasses TF quota/permission blocks)
setup-infra-bash env_file=".env":
	@chmod +x scripts/setup-infra.sh
	./scripts/setup-infra.sh "" "" "{{env_file}}"


# Build the spapparo docker container
docker-build:
	docker build -t attila:v{{version}} .

# Run the GCP discovery agent
run-discovery prompt="" env_file=".env":
	@chmod +x bin/run-discovery.sh
	./bin/run-discovery.sh "{{prompt}}" "{{env_file}}"

# Run an arbitrary command inside the container (default: bash)
docker-run env_file=".env" *cmd="bash":
	@chmod +x bin/docker-run.sh
	./bin/docker-run.sh "{{env_file}}" {{cmd}}


# Test the configuration and credentials
test-config env_file=".env":
	python3 cli/attila.py test-config {{env_file}}

test:
	echo tODO tests

# Run the container interactively with a bash shell
docker-interactive:
	@chmod +x bin/run-discovery.sh
	./bin/run-discovery.sh bash

# Run a cheap query inside the container to test authentication
docker-test-auth:
	@chmod +x bin/run-discovery.sh
	./bin/run-discovery.sh gemini -y -p "write exactly one word: success"

check:
	echo 'Quick summary of .env, is there anything missing?'

# Run the Conductor inspector to display track status
conductor-status *args="--all":
	@python3 conductor/bin/conductor-inspector {{args}}
