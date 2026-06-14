# Ektisis project plan

## Product definition

Ektisis is a local or VPS-hosted software factory for AI-assisted SaaS development.

The goal is to install a small set of Docker-based tools that make this flow possible:

```txt
human defines a task
→ AI agent changes code in a repository
→ automated checks validate the change
→ human reviews and approves
→ approved code can be merged and deployed
```

The project must avoid building abstract infrastructure for its own sake. Each phase exists to install a tool or capability needed to reach working AI-generated code.

## Initial development assumptions

The default target stack for generated software is:

```txt
Node.js
TypeScript
Next.js
React
Vite
Python when useful
Docker
```

Default project shape:

```txt
monorepo first
separate frontend/backend only when there is a clear reason
human approval before merge
free or low-cost model routes first
paid models only with explicit human approval
```

## Tooling plan

### Machine foundation

Installed on the host, not as product services:

```txt
Linux
SSH
Docker Engine
Docker Compose plugin
Git
basic firewall
runtime directory layout
```

### Source control and review

Docker services:

```txt
Gitea
PostgreSQL for Gitea
Gitea Actions Runner
```

Gitea is responsible for repositories, branches, pull requests, reviews, and CI entrypoints.

PostgreSQL is part of the Gitea phase because it is a Gitea dependency.

### Model routing

Docker services:

```txt
LiteLLM
FreeLLMAPI
```

LiteLLM is the model gateway used by agents.

FreeLLMAPI is an economical/free model route behind LiteLLM.

Target flow:

```txt
OpenHands → LiteLLM → FreeLLMAPI or configured providers
```

### AI coding agent

Docker service:

```txt
OpenHands
```

OpenHands is the first planned coding agent. Other agents can be evaluated later only after the first coding flow works.

### Quality and security checks

Initial checks:

```txt
lint
typecheck
test
build
```

Security checks after the first working coding flow:

```txt
Gitleaks
Trivy
Semgrep
```

### Future control plane

Not part of the early installation path.

Possible future tools:

```txt
Next.js control panel
PostgreSQL for Ektisis application state
Redis if queue/state is needed
Prefect if orchestration becomes necessary
observability stack only after the core flow works
```

## Phase plan

### Phase 0 — Machine

Goal:

```txt
Prepare a reliable Linux server for Ektisis.
```

Installs or validates:

```txt
SSH
Docker
Docker Compose
Git
firewall
sleep/hibernate disabled
runtime directories
```

Completion proof:

```txt
machine can be administered headlessly
Docker works without sudo for the admin user
runtime layout exists
validation passes
```

### Phase 1 — Gitea

Goal:

```txt
Install a functional Git server with CI foundation.
```

Tools:

```txt
Gitea
PostgreSQL for Gitea
Gitea Actions Runner
```

Automatic validation:

```txt
Gitea responds
PostgreSQL is healthy
Git clone/commit/push works through temporary resources
a simple runner job can execute
temporary validation resources are cleaned
```

Repository cleanup required:

```txt
old Phase 1A and Phase 1B structure must be consolidated into Phase 1 — Gitea
Git smoke testing becomes part of Phase 1, not a separate public phase
```

### Phase 2 — LiteLLM + FreeLLMAPI

Goal:

```txt
Provide a single model API for agents.
```

Tools:

```txt
LiteLLM
FreeLLMAPI
```

Automatic validation:

```txt
LiteLLM starts
FreeLLMAPI starts
LiteLLM exposes an OpenAI-compatible endpoint
LiteLLM can call the configured free/economical route
```

Completion proof:

```txt
a local request to LiteLLM returns a model response
```

### Phase 3 — OpenHands

Goal:

```txt
Install the first coding agent and connect it to Gitea and LiteLLM.
```

Tool:

```txt
OpenHands
```

Automatic validation:

```txt
OpenHands starts
OpenHands can reach LiteLLM
OpenHands can access a Gitea repository
```

Completion proof:

```txt
OpenHands can run against a lab repository
```

### Phase 4 — First AI-generated code change

Goal:

```txt
See AI create a real code change.
```

Flow:

```txt
create or use a lab repository in Gitea
create a minimal app
submit a small coding task to OpenHands
AI changes code
checks run
AI commits to a branch
human reviews the result
```

Completion proof:

```txt
a real branch exists with an AI-made code change that passed automated checks
```

### Phase 5 — Quality and security gates

Goal:

```txt
Make every proposed change pass minimum quality and security checks.
```

Checks:

```txt
lint
typecheck
test
build
Gitleaks
Trivy
Semgrep
```

Completion proof:

```txt
bad changes fail
valid changes pass
human approval remains required before merge
```

### Phase 6 — Deployment

Goal:

```txt
Turn approved code into a running application.
```

Possible tools:

```txt
Docker Compose
Caddy or Traefik
local or private image workflow
```

Completion proof:

```txt
approved code can be deployed to a reachable environment
```

### Phase 7 — Control plane

Goal:

```txt
Provide a product UI for tasks, agents, repositories, approvals, costs, and status.
```

This phase starts only after the core flow has proven value.

## Current priority

The immediate goal is not dashboard, observability, multi-agent work, or deployment.

The immediate goal is:

```txt
reach the first AI-made code change in the fewest practical phases
```

## Rules for future phase design

A phase should exist only when it installs or enables a real tool/capability.

Validation belongs inside the phase that owns the tool.

Do not create a separate public phase only to prove a sub-behavior.

Prefer:

```txt
install tool
validate automatically
clean temporary validation resources
move to the next required tool
```
