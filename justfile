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

# Build the spapparo docker container
docker-build:
	docker build -t attila:v{{version}} .

# Run the GCP discovery agent
run-discovery project_id:
	@if [ -z "$GEMINI_API_KEY" ]; then \
		echo "[-] ERROR: GEMINI_API_KEY is not set. Please add it to your .env file."; \
		exit 1; \
	fi
	docker run --rm -it \
		-e PROJECT_ID={{project_id}} \
		-e GEMINI_API_KEY="$GEMINI_API_KEY" \
		-v $(pwd)/memory/{{project_id}}:/memory \
		-v ~/git/gemini-cli-tools/tools/gcp/service-account-key.json:/etc/gcp/sa-key.json:ro \
		attila:v{{version}}
