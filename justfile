# A.TT.I.L.A. Justfile
# "A come atroce, T come terremoto, T come tragedia, I come iradiddio..."

# Load .env file automatically
set dotenv-load := true

version := `cat VERSION`

# Print help by default
default:
	@just -f {{justfile()}} --list

# Initialize the workspace for a GCP project
init project_id:
	python3 cli/attila.py init --project-id {{project_id}}

# Set up the GCP infrastructure using Terraform and extract keys
setup-infra project_id:
	@ACTIVE_IDENTITY=$$(gcloud config get-value account 2>/dev/null); \
	GCP_IDENTITY=$$(grep -E "^GCP_IDENTITY=" .env | cut -d= -f2 | tr -d '"'\'' '); \
	if [ "$$ACTIVE_IDENTITY" != "$$GCP_IDENTITY" ]; then \
		echo "[-] ERROR: Identity mismatch!"; \
		echo "    Active gcloud account: $$ACTIVE_IDENTITY"; \
		echo "    Required .env account: $$GCP_IDENTITY"; \
		echo "    Please run: gcloud config set account $$GCP_IDENTITY"; \
		exit 1; \
	fi
	@echo "[+] Running Terraform Apply..."
	cd terraform && terraform apply -var="project_id={{project_id}}" -auto-approve
	@echo "[+] Extracting Service Account Key to ./credentials.json..."
	cd terraform && terraform output -raw service_account_private_key | base64 -d > ../credentials.json
	@echo "[+] Extracting Gemini API Key and updating .env..."
	@API_KEY=$$(cd terraform && terraform output -raw gemini_api_key); \
	if [ -n "$$API_KEY" ]; then \
		sed -i "s/GEMINI_API_KEY=.*/GEMINI_API_KEY=$$API_KEY/" .env; \
		echo "[+] .env successfully updated with Gemini API Key."; \
	else \
		echo "[-] WARNING: Could not extract Gemini API Key from Terraform."; \
	fi

# Build the spapparo docker container
docker-build:
	docker build -t attila:v{{version}} .

# Run the GCP discovery agent
run-discovery project_id:
	@if [ -z "$GEMINI_API_KEY" ]; then \
		echo "[-] ERROR: GEMINI_API_KEY is not set. Please run 'just setup-infra {{project_id}}' or add it manually to your .env file."; \
		exit 1; \
	fi
	docker run --rm -it \
		-e PROJECT_ID={{project_id}} \
		-e GEMINI_API_KEY="$GEMINI_API_KEY" \
		-v $(pwd)/memory/{{project_id}}:/memory \
		-v $(pwd)/credentials.json:/etc/gcp/sa-key.json:ro \
		attila:v{{version}}
