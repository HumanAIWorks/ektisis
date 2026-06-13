# Phase 1A decisions

Phase 1A starts Gitea with PostgreSQL using Docker Compose.

## Decision: keep the first setup simple

Phase 1A uses:

```txt
Gitea HTTP: port 3000
Gitea SSH: port 2222
Database: PostgreSQL
Database SSL: disabled
Access: public IP address
```

This is intentional.

The goal of Phase 1A is to prove that the first persistent service works end to end.

End to end means:

```txt
server
→ Docker
→ PostgreSQL
→ Gitea
→ browser
```

## Decision: HTTPS comes later

Phase 1A does not configure HTTPS.

HTTPS is the secure version of HTTP. It encrypts traffic between the browser and the server.

HTTPS should be added in a later phase with a reverse proxy.

A reverse proxy is a front door service that receives web traffic and sends it to the correct internal application.

Possible future options:

- Caddy
- Traefik
- Nginx

## Decision: domain name is optional and later

Phase 1A works with a public IP address.

A domain name, such as `git.example.com`, is useful later, but it is not required to validate Gitea.

## Decision: provider firewall is documented, not automated

Ektisis can safely change things inside the machine.

Provider firewalls are controlled outside the machine, inside dashboards like OCI, AWS, Azure, or other VPS providers.

For Phase 1A, Ektisis documents the provider steps instead of changing them automatically.

VPS means Virtual Private Server. It is a rented Linux server running in a provider's datacenter.

## Validated environment

Phase 1A was validated on:

```txt
Oracle Cloud Infrastructure
Ubuntu 24.04
ARM instance
Gitea 1.26.2
PostgreSQL 16 Alpine image
```

OCI means Oracle Cloud Infrastructure, Oracle's cloud platform.
