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

HTTPS is the secure version of HTTP. It encrypts traffic between the browser and the server.

A reverse proxy is a front door service that receives web traffic and sends it to the right internal application.

## Ports

Default ports:

```txt
Gitea HTTP: 3000
Gitea SSH: 2222
```

A port is a numbered door used by a service. Here, Gitea uses port `3000` for the web page.

On a cloud VPS, the provider firewall may also need to allow port `3000` before Gitea is reachable from your browser.

VPS means Virtual Private Server. It is a rented Linux server running in a provider's datacenter.

A firewall is a rule system that decides which connections are allowed.

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

If the browser does not open Gitea, run:

```bash
bash phases/phase-1a/check-access.sh
```

This script checks whether Gitea works inside the machine and points you to the most likely documentation page.

## Open the local firewall

If the access check says the local firewall may be blocking port `3000`, run:

```bash
sudo bash phases/phase-1a/open-local-firewall.sh
```

This only changes the firewall inside the Linux machine. On a cloud VPS, you may still need to allow the same port in the provider dashboard.

## First Gitea setup

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
SSL: Disable
```

The database SSL option is for the connection between Gitea and PostgreSQL. In Phase 1A both services run inside the same Docker network on the same machine, so `Disable` is expected.

## Reset Phase 1A before real use

Use this only if the first setup failed and you want to start Phase 1A again from zero.

```bash
bash phases/phase-1a/reset.sh --yes
bash phases/phase-1a/bootstrap.sh
bash phases/phase-1a/validate.sh
```

This removes the Phase 1A database and Gitea data.

Do not use this after real repositories or users have been created, unless you intentionally want to delete them.

## Common setup error: database password failed

If Gitea shows this message:

```txt
pq: password authentication failed for user "gitea"
```

It usually means PostgreSQL was already initialized with an older password, but the `.env` file was recreated with a new password.

Before real data exists, the safest fix is a full Phase 1A reset:

```bash
bash phases/phase-1a/reset.sh --yes
bash phases/phase-1a/bootstrap.sh
bash phases/phase-1a/validate.sh
```

Then copy the new `POSTGRES_PASSWORD` from:

```bash
cat ~/ektisis-runtime/compose/phase-1a/.env
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

## Troubleshooting

Start here:

```txt
docs/troubleshooting/README.md
```

For OCI specifically:

```txt
docs/troubleshooting/oci.md
```

OCI means Oracle Cloud Infrastructure, Oracle's cloud platform.

## Completion criteria

Phase 1A is complete when:

- PostgreSQL container is running and healthy
- Gitea container is running
- Gitea HTTP responds locally
- Gitea is reachable from the browser
- the first admin user can be created
