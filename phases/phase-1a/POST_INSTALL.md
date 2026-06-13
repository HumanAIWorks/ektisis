# Phase 1A post-install checklist

Use this checklist after the Gitea installation screen is complete.

## 1. Confirm Gitea opens in the browser

Open:

```txt
http://YOUR_SERVER_IP:3000/
```

Use your own server IP.

If you do not know the address, run:

```bash
bash phases/phase-1a/check-access.sh
```

If it opens, browser access is working.

## 2. Confirm you can log in

Log in with the first administrator account created during setup.

An administrator account is the main user that can manage the Gitea instance.

## 3. Confirm the services are healthy

On the server, from the repository root:

```bash
bash phases/phase-1a/validate.sh
bash phases/phase-1a/check-access.sh
```

Expected result:

```txt
Phase 1A validated. Gitea + PostgreSQL are running.
```

## 4. Do not use reset after real data exists

After users or repositories exist, do not run:

```bash
bash phases/phase-1a/reset.sh --yes
```

That command removes the Phase 1A database and Gitea files.

Use it only before real data exists, or when you intentionally want to start over.

## 5. Current security position

Phase 1A uses HTTP over IP address.

HTTP is the basic web protocol. At this stage, it is used only to validate that Gitea works.

This is not the final public setup.

Later phases should add:

- HTTPS
- optional domain name
- reverse proxy
- backup routine

HTTPS is the secure version of HTTP. It encrypts traffic between the browser and the server.

A reverse proxy is a front door service that receives web traffic and sends it to the correct internal application.

## Phase 1A done

Phase 1A is complete when:

- Gitea opens in the browser
- the administrator account can log in
- PostgreSQL is healthy
- Gitea is running
- local validation passes
