FROM node:24-bullseye

# Install system dependencies
RUN apt-get update && apt-get install -y \
    curl \
    gnupg \
    python3 \
    python3-pip \
    git \
    && rm -rf /var/lib/apt/lists/*

# Install Google Cloud CLI
RUN echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list \
    && curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key --keyring /usr/share/keyrings/cloud.google.gpg add - \
    && apt-get update && apt-get install -y google-cloud-cli \
    && rm -rf /var/lib/apt/lists/*

# Install @google/gemini-cli globally
RUN npm install -g @google/gemini-cli@0.49.0

# Copy default settings to pre-configure Vertex AI
COPY docker-includes/harnesses/gemini-cli/settings.json /root/.gemini/settings.json

# Pre-install the Gemini SRE extension
RUN yes | gemini extensions install https://github.com/gemini-cli-extensions/sre || echo "Warning: Extension install failed during build"

# Set up working directory
WORKDIR /app

# Copy entrypoint script
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Default environment variables
ENV PROJECT_ID=""
ENV GEMINI_API_KEY=""

ENTRYPOINT ["/entrypoint.sh"]
