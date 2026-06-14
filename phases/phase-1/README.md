# Phase 1 — Factory Docker Compose Stack

Phase 1 starts the Ektisis service stack with Docker Compose.

Phase 0 prepares the machine. Phase 1 starts the services.

## Public files

```txt
phases/phase-1/README.md
phases/phase-1/run.sh
phases/phase-1/reconcile.sh
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

## Reconcile runtime

Use reconcile when generated config and running containers may be out of sync, but you do not want to delete data.

This is the safe fix for cases where `.env` has one LiteLLM key, but the running container still has an older key.

```bash
bash phases/phase-1/reconcile.sh
```

The script checks and fixes:

```txt
LiteLLM LITELLM_MASTER_KEY
LiteLLM UI_PASSWORD
OpenHands LLM_API_KEY
```

If a mismatch is found, the affected container is recreated with the current `.env`.

## Reset modes

Use `reset.sh` instead of manually deleting folders.

Default mode: recreate containers only, preserving runtime config and service data.

```bash
bash phases/phase-1/reset.sh --containers
```

Runtime mode: remove generated runtime config, including `.env`, but keep service data volumes.

```bash
bash phases/phase-1/reset.sh --runtime --yes
```

Clean mode: remove containers, generated runtime config, and Phase 1 service data. Use this for a true clean reinstall.

```bash
bash phases/phase-1/reset.sh --clean --yes
```

After `--runtime` or `--clean`, run:

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
