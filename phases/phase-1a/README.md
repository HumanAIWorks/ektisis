# Ektisis Phase 1A — Gitea + PostgreSQL

Phase 1A starts the first persistent service of the factory: a private Git server backed by PostgreSQL.

This phase assumes Phase 0 is already validated.

## What this phase does

It starts:

- Gitea
- PostgreSQL

It stores runtime files outside the repository:

```txt
~/ektisis-runtime/compose/phase-1a/.env
~/ektisis-runtime/data/postgres
~/ektisis-runtime/data/gitea
~/ektisis-runtime/data/gitea-config
```

## What this phase does not do yet

It does not configure:

- HTTPS
- domain name
- reverse proxy
- backups
- external runners
- AI agents

Those come later.

## Ports

Default ports:

```txt
Gitea HTTP: 3000
Gitea SSH: 2222
```

On a cloud VPS, the provider firewall/security list must allow port `3000` before Gitea is reachable from your browser.

## Run

From the repository root:

```bash
bash phases/phase-0/validate.sh
bash phases/phase-1a/bootstrap.sh
bash phases/phase-1a/validate.sh
```

## Open Gitea

After validation, the script prints the URL.

Example:

```txt
http://SERVER_PUBLIC_IP:3000/
```

The first time you open Gitea, complete the install screen.

Use the database values already generated in:

```bash
cat ~/ektisis-runtime/compose/phase-1a/.env
```

Expected database settings:

```txt
Database Type: PostgreSQL
Host: postgres:5432
Database Name: gitea
Username: gitea
Password: value from POSTGRES_PASSWORD
```

## Stop services

```bash
bash phases/phase-1a/down.sh
```

This stops containers but keeps data.

## Validate again

```bash
bash phases/phase-1a/validate.sh
```

## Logs

```bash
docker compose --env-file ~/ektisis-runtime/compose/phase-1a/.env -f phases/phase-1a/compose.yml -p ektisis-phase-1a logs --tail=100
```

## Completion criteria

Phase 1A is complete when:

- PostgreSQL container is running and healthy
- Gitea container is running
- Gitea HTTP responds locally
- Gitea is reachable from the browser
- the first admin user can be created
