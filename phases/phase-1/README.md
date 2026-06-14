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
PostgreSQL shared by the stack
Gitea
FreeLLMAPI
LiteLLM
Redis
OpenHands
```

PostgreSQL is a single container. It stores separate databases for the services that need PostgreSQL.

Current databases:

```txt
gitea
litellm
```

This keeps the stack simpler while preserving separation at the database level.

## Dependency rule

Service ordering belongs in Docker Compose when there is a direct dependency.

Examples:

```txt
Gitea depends on PostgreSQL
LiteLLM depends on PostgreSQL and FreeLLMAPI
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
shared PostgreSQL container is running and healthy
Gitea responds locally
FreeLLMAPI responds locally
LiteLLM readiness endpoint responds locally
Redis is running and healthy
OpenHands container is running
OpenHands HTTP responds locally
```

## FreeLLMAPI note

The current FreeLLMAPI service is a lightweight local placeholder service so the Docker Compose stack has the expected service name and dependency path.

It must be replaced by the real FreeLLMAPI image after the exact Docker image and startup contract are confirmed.
