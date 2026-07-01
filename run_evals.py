#!/usr/bin/env python3
"""
Project A.TT.I.L.A. Evaluation Runner
Uses the Gemini API to grade the agent's output against expected findings.
"""

import os
import sys
import yaml
import json
import subprocess
from pathlib import Path
from google import genai
from google.genai import types

def load_evals():
    base_dir = Path(__file__).parent
    eval_file = base_dir / "tests" / "evals.yaml"
    if not eval_file.exists():
        print(f"[-] Error: {eval_file} not found.")
        sys.exit(1)
    with open(eval_file, "r") as f:
        return yaml.safe_load(f)

def run_agent(project_id):
    print(f"[+] Running agent discovery on project: {project_id}...")
    # Trigger the just command to run the discovery
    try:
        # Pass empty prompt to use default, and pass PROJECT_ID in the env
        env = os.environ.copy()
        env["PROJECT_ID"] = project_id
        subprocess.run(["just", "run-discovery", ""], env=env, check=True)
    except subprocess.CalledProcessError as e:
        print(f"[-] Error running agent: {e}")
        sys.exit(1)

def get_latest_discovery_file(project_id):
    base_dir = Path(__file__).parent
    discovery_dir = base_dir / "memory" / project_id / "discovery"
    files = list(discovery_dir.glob("*-discovery.md"))
    if not files:
        return None
    # Sort by modification time to get the latest
    files.sort(key=lambda x: x.stat().st_mtime)
    return files[-1]

def evaluate_output(client, content, expected_findings, min_score):
    prompt = f"""
You are an expert evaluator. Your task is to grade the output of a GCP discovery agent against a list of expected findings.

---
AGENT OUTPUT:
{content}
---
EXPECTED FINDINGS:
{json.dumps(expected_findings, indent=2)}
---

Grade the output on a scale from 0.0 to 1.0 based on how many of the expected findings were correctly identified.
Provide your response in JSON format:
{{
  "score": <float between 0.0 and 1.0>,
  "reasoning": "<explanation of the grade>"
}}
"""
    try:
        response = client.models.generate_content(
            model='gemini-2.5-flash',
            contents=prompt,
            config=types.GenerateContentConfig(
                response_mime_type="application/json",
            ),
        )
        result = json.loads(response.text)
        return result["score"], result["reasoning"]
    except Exception as e:
        print(f"[-] Error calling Gemini API for evaluation: {e}")
        return 0.0, str(e)

def main():
    api_key = os.getenv("GEMINI_API_KEY")
    if not api_key:
        print("[-] Error: GEMINI_API_KEY env var not set.")
        sys.exit(1)

    project_id = os.getenv("PROJECT_ID", "sre-next")
    
    # Load evals
    config = load_evals()
    global_min_score = config.get("global", {}).get("min_score", 0.7)
    
    # Initialize Gemini client
    client = genai.Client(api_key=api_key)
    
    # Run the agent
    run_agent(project_id)
    
    # Find latest discovery file
    discovery_file = get_latest_discovery_file(project_id)
    if not discovery_file:
        print("[-] Error: No discovery file found in memory.")
        sys.exit(1)
        
    print(f"[+] Reading discovery report: {discovery_file.name}")
    content = discovery_file.read_text()
    
    # Run all tests
    all_passed = True
    for test in config.get("tests", []):
        print(f"\n--- Running Eval: {test['name']} ---")
        score, reasoning = evaluate_output(client, content, test["expected_findings"], global_min_score)
        
        print(f"Score: {score:.2f} (Threshold: {global_min_score:.2f})")
        print(f"Reasoning: {reasoning}")
        
        if score >= global_min_score:
            print("\033[32m[+] PASS\033[0m")
        else:
            print("\033[31m[-] FAIL\033[0m")
            all_passed = False
            
    if not all_passed:
        sys.exit(1)
    print("\n\033[32m[+] All evaluations passed successfully!\033[0m")

if __name__ == "__main__":
    main()
