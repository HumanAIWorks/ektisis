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

## Important: do not use DNS for this step

If you see pages like `DNS management`, `Private resolvers`, or `Private zones`, you are in the wrong place for this problem.

DNS is the system that translates names like `example.com` into IP addresses. Here we are not fixing a name yet; we are opening a network port.

## Path through the subnet

This is the easiest path from the screens shown during validation.

1. Open OCI Console.
2. Go to `Networking`.
3. Open `Virtual cloud networks`.
4. Click your VCN, for example `vcn-ektisis`.
5. Open the `Subnets` tab.
6. Click your public subnet, for example `subnet-ektisis`.
7. On the subnet page, find `Security Lists`.
8. Open the security list attached to the subnet. It is usually named something like `Default Security List for vcn-ektisis`.
9. Open `Ingress Rules`.
10. Click `Add Ingress Rules`.

A VCN is a Virtual Cloud Network. It is the private network that contains your cloud server.

A subnet is a smaller part of the VCN where your server is connected.

A Security List is an OCI firewall rule group. It decides what traffic can reach servers inside that subnet.

Ingress means traffic entering the server from outside.

## Rule to add

Suggested rule for testing:

```txt
Source CIDR: 0.0.0.0/0
IP Protocol: TCP
Source Port Range: leave blank
Destination Port Range: 3000
Description: Ektisis Phase 1A Gitea HTTP
```

CIDR is a way to describe a range of IP addresses. `0.0.0.0/0` means any IPv4 address.

TCP is the network protocol used by web pages and SSH.

Leave the source port blank because the browser can use different temporary ports when connecting to the server.

## If your instance uses a Network Security Group

Some OCI instances use a Network Security Group, also called NSG.

An NSG is another kind of OCI firewall rule group. It is attached directly to a resource, instead of only to a subnet.

If your instance has an NSG, add the same ingress rule there too:

```txt
Source CIDR: 0.0.0.0/0
IP Protocol: TCP
Destination Port Range: 3000
```

## Try again

After adding the rule, open:

```txt
http://PUBLIC_IP:3000/
```

For the current Phase 1A test, this looks like:

```txt
http://137.131.191.182:3000/
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
