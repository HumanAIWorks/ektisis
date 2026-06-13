# Local network access guide

This guide is for a machine running at home, in an office, or in a private local network.

A local network is the network behind your router. Local IPs often start with `192.168`, `10`, or `172.16` to `172.31`.

## Symptom

Gitea works on the machine, but you cannot open it from another computer.

Example:

```txt
http://192.168.15.12:3000/
```

## First check

On the Ektisis machine, run:

```bash
bash phases/phase-1a/check-access.sh
```

If Gitea responds inside the machine, the application is probably fine.

## Open the local firewall

The local firewall is the firewall running inside the Linux machine itself.

Run:

```bash
sudo bash phases/phase-1a/open-local-firewall.sh
```

Then try from another device on the same network:

```txt
http://LOCAL_IP:3000/
```

Use the local IP shown by `MACHINE.md` or by `check-access.sh`.

## If you want to access it from outside your home

Then your router must forward the port to the Ektisis machine.

Port forwarding means telling the router: when someone reaches this public port, send the traffic to this machine inside the local network.

Typical router rule:

```txt
External port: 3000
Internal IP: your Ektisis local IP
Internal port: 3000
Protocol: TCP
```

TCP is the network protocol used by web pages and SSH.

## Important: CGNAT

Some internet providers use CGNAT.

CGNAT means your home connection does not receive a normal public IPv4 address directly. In that case, port forwarding may not work even if your router is configured correctly.

If CGNAT is present, common alternatives are:

- use a VPS instead of a home machine
- ask the provider for a public IP
- use a tunnel service later, when Ektisis supports it

## Recommended for now

For early Ektisis testing, use local access inside your own network, or use a VPS such as OCI.
