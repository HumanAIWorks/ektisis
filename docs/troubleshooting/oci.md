# Oracle Cloud Infrastructure access guide

This guide is for Oracle Cloud Infrastructure, also called OCI.

OCI is Oracle's cloud platform. When you create a VM instance there, it can have its own firewall rules outside the machine.

## Symptom

Gitea is running, but this does not open in your browser:

```txt
http://PUBLIC_IP:3000/
```

## First check

On the server, run:

```bash
bash phases/phase-1a/check-access.sh
```

If it says Gitea responds inside the machine, the application is probably fine.

The likely missing step is allowing port `3000` in OCI.

A port is a numbered door used by a service. Gitea uses port `3000` for the web page in Phase 1A.

## What to change in OCI

In the OCI Console, look for the network rules connected to your instance.

Usually this is in one of these places:

```txt
Virtual Cloud Network
→ Security Lists
```

or:

```txt
Virtual Cloud Network
→ Network Security Groups
```

Security List and Network Security Group are OCI firewall rule groups. They decide what traffic can reach your server.

Add an ingress rule.

Ingress means traffic entering the server from outside.

Suggested rule for testing:

```txt
Source CIDR: 0.0.0.0/0
IP Protocol: TCP
Destination Port Range: 3000
Description: Ektisis Phase 1A Gitea HTTP
```

CIDR is a way to describe a range of IP addresses. `0.0.0.0/0` means any IPv4 address.

TCP is the network protocol used by web pages and SSH.

## Try again

After adding the rule, open:

```txt
http://PUBLIC_IP:3000/
```

If it still does not open, run:

```bash
bash phases/phase-1a/check-access.sh
```

Then check that the local firewall allows port `3000`:

```bash
sudo bash phases/phase-1a/open-local-firewall.sh
```

## Security note

Opening `3000` to `0.0.0.0/0` is simple for testing.

For a real public service, later phases should add HTTPS, a domain name, and stronger access rules.

HTTPS is the secure version of HTTP. It encrypts traffic between the browser and the server.
