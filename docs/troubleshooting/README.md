# Troubleshooting access problems

This guide helps when a service is running on the machine, but you cannot open it from your browser.

The goal is to avoid guessing. We check one layer at a time.

## Simple mental model

When you open Gitea in your browser, the connection passes through a few layers:

```txt
Browser
→ internet or local network
→ cloud provider firewall or router
→ machine firewall
→ Docker
→ Gitea
```

A firewall is a rule system that decides which connections are allowed.

A port is a numbered door used by a service. In Phase 1A, Gitea uses port `3000` for the web page.

## First command to run

From the repository root:

```bash
bash phases/phase-1a/check-access.sh
```

This script checks whether Gitea works inside the machine and then points you to the most likely next step.

## Most common situations

### Gitea works locally, but the browser does not open it

This usually means one of these is blocking access:

- the local firewall on the machine
- the cloud provider firewall
- the home router, if this is a local machine

### Gitea does not work locally

Then the problem is probably inside the machine, Docker, or Gitea itself.

Run:

```bash
bash phases/phase-1a/validate.sh
```

Then inspect logs:

```bash
docker compose --env-file ~/ektisis-runtime/compose/phase-1a/.env -f phases/phase-1a/compose.yml -p ektisis-phase-1a logs --tail=100
```

## Environment-specific guides

Use the guide that matches your environment:

- [Oracle Cloud Infrastructure](./oci.md)
- [Local network or home machine](./local-network.md)
- [Generic VPS or cloud server](./generic-vps.md)

VPS means Virtual Private Server. It is a rented server running in a provider's datacenter.

## Rule of thumb

Ektisis can safely automate what happens inside the machine.

For things controlled by a provider, such as OCI, AWS, Azure, Hetzner, DigitalOcean, or another VPS panel, Ektisis should guide you instead of changing provider settings silently.
