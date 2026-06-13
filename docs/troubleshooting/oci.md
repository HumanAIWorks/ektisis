# Oracle Cloud Infrastructure access guide

This guide is for Oracle Cloud Infrastructure, also called OCI.

OCI is Oracle's cloud platform. When you create a VM instance there, it can have its own firewall rules outside the machine.

This path was validated with Ektisis Phase 1A on OCI in the Brazil East, Sao Paulo region.

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

If it also says the local firewall allows port `3000`, then the machine is ready. The remaining step is usually in the OCI Console.

A port is a numbered door used by a service. Gitea uses port `3000` for the web page in Phase 1A.

## Important: do not use DNS for this step

If you see pages like `DNS management`, `Private resolvers`, or `Private zones`, you are in the wrong place for this problem.

DNS is the system that translates names like `example.com` into IP addresses. Here we are not fixing a name yet; we are opening a network port.

## Validated path through the subnet

This is the path that worked during the Phase 1A OCI validation.

1. Open OCI Console.
2. Go to `Networking`.
3. Open `Virtual cloud networks`.
4. Click your VCN, for example `vcn-ektisis`.
5. Open the `Subnets` tab.
6. Click your public subnet, for example `subnet-ektisis`.
7. Open the `Security` tab.
8. In `Security Lists`, click the attached security list, for example `Default Security List for vcn-ektisis`.
9. Open the `Security rules` tab.
10. Find the `Ingress Rules` section.
11. Click `Add Ingress Rules`.

A VCN is a Virtual Cloud Network. It is the private network that contains your cloud server.

A subnet is a smaller part of the VCN where your server is connected.

A Security List is an OCI firewall rule group. It decides what traffic can reach servers inside that subnet.

Ingress means traffic entering the server from outside.

## Rule to add

Suggested rule for testing:

```txt
Stateless: No / unchecked
Source Type: CIDR
Source CIDR: 0.0.0.0/0
IP Protocol: TCP
Source Port Range: leave blank
Destination Port Range: 3000
Description: Ektisis Phase 1A Gitea HTTP
```

CIDR is a way to describe a range of IP addresses. `0.0.0.0/0` means any IPv4 address.

TCP is the network protocol used by web pages and SSH.

Leave the source port blank because the browser can use different temporary ports when connecting to the server.

You may already see a similar rule for SSH on port `22`. SSH is the secure terminal access used to connect to the server. This new rule does the same kind of opening, but for Gitea on port `3000`.

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

Example:

```txt
http://137.131.191.182:3000/
```

If it opens, the OCI network rule is working.

If it still does not open, run:

```bash
bash phases/phase-1a/check-access.sh
```

Then check that the local firewall allows port `3000`:

```bash
sudo bash phases/phase-1a/open-local-firewall.sh
```

## What check-access can and cannot prove

`check-access.sh` can prove that Gitea works inside the machine and that the local Linux firewall appears to allow the port.

It cannot fully prove that your browser, from outside OCI, can reach the service. That final confirmation must be done by opening the URL in a browser or by testing from another network.

## Security note

Opening `3000` to `0.0.0.0/0` is simple for testing.

For a real public service, later phases should add HTTPS, a domain name, and stronger access rules.

HTTPS is the secure version of HTTP. It encrypts traffic between the browser and the server.
