---
version: 1.0
notes: This is in ric life, then copied into GH attila.
deps: none.
---
I want to create a complex, extendable tool for SRE investigations on GCP.

The idea is to have two pieces:

1. A setup CLI tool, called ATTILA. Name is taken from Attila, flagello di Dio with Diego Abbattantuono.
2. An applet/investigation agent, ultimately running inside Docker.

Tool is in **English** and code should be all in English (some italian quotes are accepted - possibly rendered in Italic and with italian flag emoji for POLA)

## 1. ATTILA (The "king", setup CLI)

Given a billed project on GCP, `attila` will be able to accomplish these functions:
- setup correctly its minions ("spappari").
- perform some sanity checks, cost analysis, metrics.

### 1. Initial setup

In input, it will just get a PROJECT_ID, with billing enabled, and an optional GCS bucket where to store info. If not given, it'll be created with deterministic name (eg, `gs://PROJECT_ID-attila-config/`). This will come into .env.
Note GCS bucket is an inpuit to terraform as it holds the state under BUCKET/tfstate/

### 2. Terraform setup

- Set up **GCS**, if needed, eg gs://PROJECT_ID-attila-public/ and gs://PROJECT_ID-attila-private/
  - `gs://PROJECT_ID-attila-public` will be a public bucket and will be used from the harness to exchange public, non-authenticated HTML pages with research, ideas, plans, ..
  - `gs://PROJECT_ID-attila-private` will hold the results of the investigations, playbooks, memory, and intimate parts of the system.
- set up a restricted `Gemini API KEY`. this will be only able to access gemini, and will be the heart of agentic behaviour inside the harness. It would be nice to create a different key per spapparo to be able to monitor costs and invalidate the keys should the barbarian go rogue
- **Service Account** Setup. See "Safe investigation" skill in SRE Extension. The name will be `safe-sre-investigator@...` (using SA impersonation instead of local JSON key files).
- **Pub/Sub**. We want communication to happen via well-documented P/S pathways. This will allow a proliferation of workflows (ie, let me add a Telegram channel here, lets me get GMail notifications there, let me trigger a new agent whenever XX happens, and so on).

### 3. test

Since GCP supports Org Policies which can override our abilities, we should create a small tool to test our configuration.

A tool like `attila test-config <.env.configXXX>` should be created and used to test a configuration.
Note multiple confgiurations shall be possible (personal vs work account, Org 1 vs Org 2, ..).
The tool must be able to swap between multiple accounts ignoring the local machine current `gcloud application-default credentials`.
to achieve this, some JSON files might have to be token to some local workspace. 

Things to be tested: 
- project eixsts, and is in good standing (billing enabled)
- SA created 
- GCS buckets created 
- gcloud as SA login works 
- Gemini API Key created and working (a s imple llm R/R works with that key)
- harness exec authenticates correctly (eg running Gemini CLI with "What time is it?" works).
- boilerplate functionality shoudl also be there (eg gemini cli integration is there, agy is not? Good add two lines with the latter "not implemented yet").
- finally an end2end (asking Harness to enumerate GCS buckets and show list).

Do tests in order of speed (ie, keep LLM questions for last so we fail fast).

## 2. Spapparo (the "barbarian" harness).

From an agentic SRE perspective, we want to have a "thin client". We don't want to overload this with logic, rather have a clean /simple/maintainable part and delegate complex stuff to the SRE Extension. SRE Extension is the real star here, and we want to piggyback functionality in the extension itself!

### What Harness?

The harness could be any of this:
* bespoke ADK agent
* Simple `agy` (Antigravity CLI). However, agy doesnt support API KEY so authentication might be an issue
* Simple `gemini` (Gemini CLI). This does support API KEY so it might be the easiest initial path, but let's remember GC was deprecated on May 2026 so it might not run for long.

### harness skills

Harness must download and have ALL skills availbe from SRE Extension.
We might have to maintain a few more just as "bespoke" connectors.

### harness tools

Harness MUST have a few MCP tools pre-loaded/pre-configured. for instance:

* `safe_gcloud_exec(cmd="gcloud ...", format='json', options=[])`. This will be called from the harness and enabled by default. This is the most important tool in the toolkit. It should be SAFE by default.
* `bq_gsql_exec(sql="SELECT ...", format='json', opts=[])`. This will be called from the harness and enabled by default to erxecute SQL queries.
* `promql_exec(sql="PromQL query", format='json', options=[])`. This will be called from the harness and enabled by default to erxecute PromQL queries.

All invocations need to be file-system first, to optimize for local testing and reiterating so the output format will default to JSON (or CSV depending on cases). We want to ensure that the harness can retrieve local artifacts of discovery to be token efficient and to allow agent/subagent efficient conversation (pass the file vs passing the whole otuput).

### harness Memory

Memory is crucial to this project. Let's start with a Karpathy/Obsidian-oriented Markdown memory (now sqlite for now). We cna have a standard memory (always available) and a sticky memory (per project) with this structure:

* memory/
  * <Project ID>/
    * DISCOVERY.md # Latest discovery
    * ARCHITECTURE.md
    * architecture.json # A JSON list of itnertwined resources
    * discovery/
      * 2026-06-01.md # Daily discovery
      * 2026-06-15.md
    * playbooks/
    * incidents/
    * investgations/
    * notes/
    * reports/
    * rules/ # Custom Rules, order matters (Org > Team > User)
      * 10-org.md
      * 20-team.md
      * 30-user.md

TODO(): we need to figure out a way to safely store Org/Team rules which CANNOT be over-written. This goes in v2.0, for now we're just optimistic.

**Note**: GCS sync needs to be BI-DIRECTIONAL (ok to pay performance price for this).

### Modalities

A spapparo will be able to do two things:

* **GCP Discovery**: given nothing (or some sample non-interactive prompt), it will discover the GCP landscape and create a high-level map of it, stored in Markdown and JSON.
  * Note that resources have aunique id in GCP which ResourceManager and AssetManager support. Let's use that unique name in JSON and DOT file configs to signify thje complex intertwining. Note that there are multiple dimensions:
    * Project/Folder/Org hierarchy
    * Network connections
    * Data plane (how data flow between parts)
    * Message plane (how messages are sent through PubSub, Event Arc, ..)
    * Serverless triggers: GCF / Cloud Run / P/S triggers / ..
    * CI/CD: Cloud build, GHA, Artifact Repo, ..
    * Traffic to "Compute" (GKE, Run, GCE, ..)
    * Cost. What is costing the most in this project? Is it aligned to business or are we having a rogue GCF?
    * Business. This is the only part which can't be inferred but needs to b provided by humans as an input.
* **Headless Investigation**. This is the core of the system. 
  * A spapparo will be triggered with a new investigation which comes in any possible form.
  * Possible Input: An email, a prompt, a link to URL to read, A ticket, An SLO violation.
  * An investigation will have a unique ID (UUID) and a Timestamped folder in the sticky memory.
  * The sysem knows it needs to investigate WITHOUT asking any question. 
  * The **output** fo an investigation is:
    * a message on P/S containing a small JSOn with the following parts:
    * a nice HTML in the public GCS bucket which is provided in the end (yes, nice CSS and all!)


## Functional requirements

### Observability

This is an observability exercise, so o11y needs to be at the center of the coding. We want to enable OpenTelemetry both in agents and all. 
It's particularly important to keep an eye on money:
* How much is the setup costing?
* How much is an agentic run costing? 
We want to have an infrastructrue which allows this to be accounted for, also I/O tokens spent per LLM call per API KEY, broekn down by Gemini model called.

Also all activity from Harnesses running in docker container should be extensively logged somewhere. We should be able to find conversation legft by agent X on executiojn Y some time 10 days ago. This can be achieved via Cloud Logging OR by copying/mounting ~/.gemini/..../ conversations in GCS (note this cannot be BRITTLE, we cant expect the docker container to just terminate gracefully all the time! So a cron job which rsyncs files every 30m doesnt cut it). This is probably harness specific.

## Use Cases

### UC01: Docker-As-An-Agent (CLI Wrapper)

A `docker run` execution should, by default, act as the agent execution itself.

**Is this a good idea?**
Yes, but only if implemented with **flexible delegation**:

1.  **Bake, Don't Fetch**: Pre-install the Gemini SRE extension and all dependencies during the `docker build` phase. Running `gemini extensions install` on every startup is too slow and depends on network availability.
2.  **Pass-Through Execution**: The entrypoint should set up the GCP credentials/impersonation and then check if arguments were passed:
    *   *No arguments:* Execute the default discovery/investigation agent (`exec gemini -y -p "$PROMPT"`).
    *   *Arguments passed:* Execute the arguments directly (e.g., `docker run attila:v0.1.0 bash` or `docker run attila:v0.1.0 gcloud storage ls`). This preserves debuggability.
3.  **State Isolation**: All agent state must be written to `/memory`, which is mounted from the host. The container itself remains stateless and disposable.

### Extensive testing

Creating deterministic code is ~simple. Creating LLM agentic code is hard. It's imperative that we create a rich testing framework around the agentic parts; the idea is to keep agentic pathways as simple as possible, test them locally and ensure they work in some canonical way. We're happy to change the architecture if this allows for better testing.

Every feature should come with a suite of Unit Tests (TDD philosophy), Integration Tests as needed and also Acceptance Tests (is user happy with this?). For instance, if TF code is created. the fact that it compiles is NOT sufficient. Code needs to be deployed to some "virgin" project and the functionality provided by the TF code needs to be tested (eg: the Gemini api key is correctly created and it works, the P/S topics are created and the agent is able to publish/subscribe to them, etc...). We'll need to be creative how to do this for large TF codebases, but we need to make sure we have a path forward.

LLM behaviour needs to be **evaluated**. Evals will take the form of LLM-judged evals. These evals need to be run frequently in CI. Since these evals cost money and time, these needs to be kept SEPARATE from normal unit tests:

`just test` will run quick unit tests
`just test-all` will run everything, included long-running tasks.

An EVAL usually consists of an array of these:


- a short user story
- test data (inputs)
- expected results
- numeric evals on how we did, and a cut off (test pass or fail), at a configurable threshold initialized at 70%.

All this information needs to be stored in a structured way and also made available for later reference (eg for audit, regression, or just curiosity). The user prefer YAML as its more readable and prompts are easier to maintain.

### GCP

This is a GCP-native project. Let's try to make a smart use of GCP tech:
- ADK as coding stack
- Gemini Enterprise as where the agent will land.

However, since the dev is a power user, bits and pieces will need to be tastable from a local environment, with simple `docker run` to test the pieces and allow a local-first dev cycle (bugs are easier to identify/fix if we don't have to wait 5min for a pusgh all the time!).

### OUT OF SCOPE: Multi-project

The architecture for the moment is single-project. I will be extended to multi-project (attila being able to create N spappari for N projects) but this will NOT be covered until v2.0.

### Approvals flow (v1.0+)

The system should be able, through Pub/Sub, to support an approval flow the idea is:
1. Harness finds the culript and thinks its able to fix it. However, thuis requires a mutation the syem cannot execute.
2. Harness then sends a payload to a Pub/Sub per-project topic with the following Schema:
  1. propossed command.
  2. Risk factor (see SRExt): an red/green/orange/yellow emoji followed by how risky it is and why
  3. What is this command trying to achieve (eg "I need to drain this pod to then be able to restrat the service with new fresh clean code").

### Security

The setup will create a "Safe SRE Investigator" service account with minimal permissions to do the job.

This will default to "VIEW ALL" (viewer) and the only mutations available to the SA will be "safe" things like Cloud Ops Dashboard creation, BQ USer to run SQL queries and so on.

Access to DB should be guaranteed to be READ-ONLY (not sure how to ensure that, could be grepping out `UPATE/DESTROY/DROP` inside SQL statements - TBD.

This SA will be given to the docker container to allow it to operate. The container will also be given a path to the google credentials JSON key (usually in `~/git/gemini-cli-tools/tools/gcp/service-account-key.json`).

Let's be anal about security: if I forgot anything make sure to suggest a safer, securer way to do things!

### Why docker?

I wasnt to be sure to encapdsulate all permissions to GCP - which can be scary inside the container.
This goes in 2 ways:

1. if done well, you can then say "knowck yourself out and do whatever you want". So by implementing this encapsulation we can actually let the LLM go wild.
2. Needs to have some sort of gcloud auth token passed inside the docker container.

### Style

- Make it funny, full of quotes from Diego Abattantuono movies. Exp "Attila Flagello di Dio"
- use colors and emoji in CLI.
- Use Carlessian CLI skill to build.

## Coding

1. Use /roastme until all the specs are WELL understood.
2. Use Conductor worktree Skill to implement this.
3. Use a VERSION file, and a CHANGELOG.md to track changes. Push to tags for major version changes (say 0.1 but not 0.1.1).
4. Map dockerfile to the same version ("attila:v0.1"), in `just docker-build` and `just docker-run`.

The repo will be a new PUBLIC repo under ~/git/attila/, created as public repo via palladius/attila.
Since I',m a developer Advocate for Google cloud for AI and SRE, this repo needs to be very well documented, understandable, eays to ninstall for day-0 users. We might want to also maintain an `LLMS.txt` for agentic readers. this also means maintaining a `.env.dist` and make it easy for people to adopt/read this. Use colors and emojis, and MERMAID or Excalidraw graphs in the README.md as needed to explain architecture.

### Coding iteration

Let's iterate quick. I want to have a working POC by end of day. The first thing I want to be able to do is:

### Version v0.2 (by EOD July 1st):

1. terraform works for user ricc@gcp.altostrat.com in project id `sre-next`.
2. I have a local docker container being able to start the harness to do discovery for the project `sre-next` and save the result as files in the local directory `discovery`, opportuntely mounted on GCS created bucket. If this is too complicated, its also ok to have a docker container running on qa local folder which is STICKY and mounted across muiltiple interactions. While the agent works on its /workspace/ (or whatever) I want to see that mounted folder populating new files which i can observe on my vscode, and why not also communicate with it!
3. The folder memory is STICKY.


## References

[1] SRE Extensions: gemini extensions install https://github.com/gemini-cli-extensions/sre
[2] `~/git/gemini-cli-palladius-public-goodies/skills` 🎲 create-cli-best-practices- Rules to create and maintain a GOOD CLI. Do not use for GUI-only design rules, web apps, or backend REST APIs.
[3] Internal bug:  b/528279164. 
[4] PromQL: https://docs.cloud.google.com/monitoring/promql
[5] Antigravity CLI and UI: https://antigravity.google/download
[6] Gemini CLI: https://geminicli.com/. install and stuff: `npm install -g @google/gemini-cli`
[7] POLA https://en.wikipedia.org/wiki/Principle_of_least_astonishment
