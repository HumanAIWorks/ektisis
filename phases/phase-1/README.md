# Phase 1 — Factory Docker Compose Stack

Phase 1 starts the Ektisis service stack with Docker Compose.

Phase 0 prepares the machine. Phase 1 starts the services.

## Public files

```txt
phases/phase-1/README.md
phases/phase-1/run.sh
phases/phase-1/compose.yml
```

## Run

From the repository root:

```bash
bash phases/phase-1/run.sh
```

The script prepares runtime configuration, runs Docker Compose, and validates the services.

## Services in this compose

```txt
Gitea
PostgreSQL for Gitea
LiteLLM
PostgreSQL for LiteLLM
Redis
OpenHands
```

PostgreSQL for Gitea is included because Gitea depends on it.

PostgreSQL for LiteLLM is included because LiteLLM uses it for proxy state, virtual keys, and persistence.

Redis is included as a shared lightweight infrastructure service for later orchestration needs.

## Dependency rule

Service ordering belongs in Docker Compose when there is a direct dependency.

Examples:

```txt
Gitea depends on PostgreSQL for Gitea
LiteLLM depends on PostgreSQL for LiteLLM
OpenHands depends on LiteLLM and Gitea
```

## Runtime files

Runtime files are created outside the repository:

```txt
~/ektisis-runtime/compose/phase-1/.env
~/ektisis-runtime/compose/phase-1/litellm-config.yaml
~/ektisis-runtime/data/
~/ektisis-runtime/projects/
```

The repository keeps the source compose file. Secrets and generated runtime config stay out of Git.

## Validation

After `docker compose up`, the script validates:

```txt
Gitea PostgreSQL container is running and healthy
Gitea responds locally
LiteLLM PostgreSQL container is running and healthy
LiteLLM readiness endpoint responds locally
Redis is running and healthy
OpenHands container is running
OpenHands HTTP responds locally
```

## Current limitation

FreeLLMAPI is represented in the LiteLLM configuration as an OpenAI-compatible route target.

A Docker service for FreeLLMAPI should only be added after the exact image and startup contract are confirmed, so the main compose does not intentionally include a broken placeholder service.
