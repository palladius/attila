#!/usr/bin/env python3
"""
Project A.TT.I.L.A. (Flagello di Dio) - Setup and Orchestration CLI.
"A come Atrocita, TT come Terraform e Tragedia, I come Iradiddio..."
"""

import os
import sys
import argparse
from pathlib import Path

VERSION = "0.1.0"

ATTILA_ART = r"""
        ______      __    __      _                 
       /      \    |  \  |  \    | |                
      /  ▓▓▓▓▓▓\  ▓▓▓▓▓▓▓▓▓▓▓▓▓▓ |▓▓  ______        
     |  ▓▓__| ▓▓ ▓▓  ▓▓  ▓▓  ▓▓  |▓▓ /      \       
     |  ▓▓    ▓▓| ▓▓ ▓▓ ▓▓ ▓▓ ▓▓ |▓▓|  ▓▓▓▓▓▓\      
     |  ▓▓▓▓▓▓▓▓ \▓▓ ▓▓\▓▓ ▓▓\▓▓ |▓▓| ▓▓    ▓▓      
     |  ▓▓  | ▓▓   | ▓▓  | ▓▓  | ▓▓| ▓▓▓▓▓▓▓▓      
     |  ▓▓  | ▓▓   \▓▓   \▓▓   \▓▓|▓▓\▓▓     \      
      \▓▓   \▓▓                \▓▓ \▓▓▓▓▓▓▓      
                                                    
             "Flagello di Dio!" 🗡️
"""

QUOTES = [
    "A come atroce, T come terremoto, T come tragedia, I come iradiddio, L come laco de sangue, A come... come Attila!",
    "Ma che è 'sta roba? È la spada di Attila! Chi la impugna è il re dei re!",
    "Sbabbari! Uomini di inaudita ferocia, ma con un grande cuore...",
    "Noi sbabbari, prima rademo al suolo e poi discutiamo!",
    "Ma quale imperatore? Io sono Attila, il re dei re!",
]

def print_quote():
    import random
    print(f"\033[33m\"{random.choice(QUOTES)}\"\033[0m\n")

def init_project(project_id, storage, harness):
    print(f"\033[32m[+] Initializing barbarian agent for project: {project_id}...\033[0m")
    
    # Define directory paths (pointing to project root)
    base_dir = Path(__file__).parent.parent
    memory_dir = base_dir / "memory" / project_id
    discovery_dir = memory_dir / "discovery"
    rules_dir = memory_dir / "rules"
    investigations_dir = memory_dir / "investigations"
    
    # Create directories
    for d in [discovery_dir, rules_dir, investigations_dir]:
        d.mkdir(parents=True, exist_ok=True)
        print(f"    - Created directory: {d.relative_to(base_dir)}")
        
    # Write a default user rule
    user_rule_file = rules_dir / "30-user.md"
    if not user_rule_file.exists():
        user_rule_file.write_text(f"""# User Rules for {project_id}

- Focus on identifying GCS Buckets, Cloud Run Services, and GKE Clusters.
- Highlight any resource that has no active traffic or is costing unusually high.
- Always output the resource graph in JSON format under `/memory/architecture.json`.
""")
        print(f"    - Created rule file: {user_rule_file.relative_to(base_dir)}")

    # Write .env file if it doesn't exist
    env_file = base_dir / ".env"
    if not env_file.exists():
        env_content = f"""# A.TT.I.L.A. Environment Configuration
PROJECT_ID={project_id}
STORAGE_TYPE={storage}
HARNESS={harness}
GEMINI_API_KEY=YOUR_GEMINI_API_KEY_HERE
"""
        env_file.write_text(env_content)
        print(f"\033[32m[+] Created .env configuration file. Please populate your GEMINI_API_KEY!\033[0m")
    else:
        print(f"\033[33m[!] The .env file already exists, skipping creation.\033[0m")

    print(f"\033[32m[+] Done! The barbarian is ready to discover the project!\033[0m")

def run_agent(project_id, storage, harness):
    print_quote()
    print(f"\033[31m[!] WARNING: Starting the spapparo agent...\033[0m")
    print(f"    - Project: {project_id}")
    print(f"    - Harness: {harness}")
    print(f"    - Storage: {storage}")
    
    # Check for .env
    base_dir = Path(__file__).parent.parent
    env_file = base_dir / ".env"
    if not env_file.exists():
        print(f"\033[31m[-] Error: .env file not found. Run 'attila init' first!\033[0m")
        sys.exit(1)
        
    # Check for service account key
    sa_key_path = Path.home() / "git/gemini-cli-tools/tools/gcp/service-account-key.json"
    if not sa_key_path.exists():
        print(f"\033[33m[!] Warning: Service Account key not found at {sa_key_path}.\033[0m")
        print(f"    Ensure it is present before running the Docker container.")

    # We will print the docker run command that can be executed
    print("\033[32m[+] To start the container, run:\033[0m")
    print(f"    just run-discovery {project_id}")

def main():
    parser = argparse.ArgumentParser(
        description="ATTILA: Stateful Gemini Managed Agents via GCS/Docker",
        epilog="\"Noi sbabbari, prima rademo al suolo e poi discutiamo!\""
    )
    parser.add_argument("--version", action="version", version=f"%(prog)s {VERSION}")
    
    subparsers = parser.add_subparsers(dest="command", required=True)
    
    # Init command
    init_parser = subparsers.add_parser("init", help="Initialize the workspace for a project")
    init_parser.add_argument("--project-id", required=True, help="GCP Project ID")
    init_parser.add_argument("--storage", choices=["local", "gcs"], default="local", help="Storage type (default: local)")
    init_parser.add_argument("--harness", choices=["geminicli", "adk"], default="geminicli", help="Agent harness (default: geminicli)")
    
    # Run command
    run_parser = subparsers.add_parser("run", help="Start the spapparo investigation")
    run_parser.add_argument("--project-id", required=True, help="GCP Project ID")
    run_parser.add_argument("--storage", choices=["local", "gcs"], default="local", help="Storage type (default: local)")
    run_parser.add_argument("--harness", choices=["geminicli", "adk"], default="geminicli", help="Agent harness (default: geminicli)")
    
    args = parser.parse_args()
    
    print(ATTILA_ART)
    
    if args.command == "init":
        init_project(args.project_id, args.storage, args.harness)
    elif args.command == "run":
        run_agent(args.project_id, args.storage, args.harness)

if __name__ == "__main__":
    main()
