# Phase 1 — Factory Docker Compose Stack

Phase 1 starts the Ektisis service stack with Docker Compose.

Phase 0 prepares the machine. Phase 1 starts the services.

## Public files

```txt
phases/phase-1/README.md
phases/phase-1/run.sh
phases/phase-1/reset.sh
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

## LiteLLM access

LiteLLM has two different credential types:

```txt
UI_USERNAME / UI_PASSWORD
LITELLM_MASTER_KEY
```

Use `UI_USERNAME` and `UI_PASSWORD` to sign in to the LiteLLM dashboard at `/ui`.

Use `LITELLM_MASTER_KEY` only as an API key, normally as an `Authorization: Bearer ...` token for API clients.

The `run.sh` script generates these values in:

```txt
~/ektisis-runtime/compose/phase-1/.env
```

At the end of a successful run, the script prints the LiteLLM UI username, UI password, and API key.

## Reset to Phase 0 baseline

Use `reset.sh` to remove Phase 1 and return the machine to the post-Phase-0 baseline, as if Phase 1 had not been executed.

```bash
bash phases/phase-1/reset.sh --yes
```

This removes:

```txt
Phase 1 containers and Compose network
Phase 1 generated config
Phase 1 service data
Phase 1 workspace and logs
local UFW rules opened by Phase 1
```

This keeps:

```txt
operating system setup
SSH
Docker
repository clone
Phase 0 baseline
```

After reset, run Phase 1 again with:

```bash
bash phases/phase-1/run.sh
```

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

FreeLLMAPI is exposed on its configured port because its dashboard is part of the initial manual configuration flow.

LiteLLM still talks to FreeLLMAPI internally through the Docker Compose network using:

```txt
http://freellmapi:3001/v1
```
