# Generic VPS or cloud server access guide

This guide is for a rented server when we do not yet have provider-specific instructions.

VPS means Virtual Private Server. It is a rented Linux server running in a provider's datacenter.

Examples of providers:

- Oracle Cloud Infrastructure
- AWS
- Azure
- Hetzner
- DigitalOcean
- Linode
- OVH
- Hostinger

## Symptom

Gitea works inside the server, but this does not open in your browser:

```txt
http://PUBLIC_IP:3000/
```

## First check

On the server, run:

```bash
bash phases/phase-1a/check-access.sh
```

If it says Gitea responds inside the machine, then Gitea is probably working.

The problem is probably a firewall rule.

A firewall is a rule system that decides which connections are allowed.

A port is a numbered door used by a service. Gitea uses port `3000` for the web page in Phase 1A.

## Open the local firewall

This changes the firewall inside the Linux machine:

```bash
sudo bash phases/phase-1a/open-local-firewall.sh
```

Then test again:

```txt
http://PUBLIC_IP:3000/
```

## Check the provider firewall

Many VPS providers also have an external firewall in their website dashboard.

Look for names like:

```txt
Firewall
Security Group
Network Security Group
Security List
Inbound Rules
Ingress Rules
```

Inbound or ingress means traffic entering your server from outside.

Add a rule like this:

```txt
Protocol: TCP
Port: 3000
Source: anywhere / 0.0.0.0/0
Description: Ektisis Phase 1A Gitea HTTP
```

TCP is the network protocol used by web pages and SSH.

`0.0.0.0/0` means any IPv4 address. This is simple for testing, but later you may want stricter rules.

## If your provider is not documented yet

That is expected. Ektisis cannot validate every provider at once.

The generic requirement is:

```txt
Allow inbound TCP traffic to port 3000.
```

Then open:

```txt
http://PUBLIC_IP:3000/
```

## Later improvements

Future Ektisis phases should add:

- HTTPS
- domain name
- reverse proxy
- stricter public access rules

HTTPS is the secure version of HTTP. It encrypts traffic between the browser and the server.

A reverse proxy is a front door service that receives web traffic and sends it to the right internal application.
