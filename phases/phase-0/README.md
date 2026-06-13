# Phase 0 — Prepare a headless server

[Português do Brasil](./README.pt-BR.md)

Phase 0 prepares a Debian or Ubuntu machine to behave as a reliable server for Ektisis.

The goal is not to install the full platform yet. The goal is to reach the smallest reliable base for the next phase.

## Idempotency contract

Phase 0 is designed to be repeatable.

You should be able to run the Phase 0 scripts more than once on the same machine.

Expected behavior:

- `doctor.sh` only inspects the machine and makes no changes.
- `bootstrap.sh` applies the baseline and skips items that are already correct.
- `validate.sh` checks whether the final state is ready for the next phase.
- `generate-machine-md.sh` rewrites the local machine inventory.

Important limits:

- `bootstrap.sh` does not overwrite an existing Docker data directory when containers already exist.
- SSH hardening is documented as a manual optional step because locking yourself out is possible.
- Router DHCP reservation is manual because it happens outside the server.
- BIOS or UEFI settings are manual because scripts cannot control them safely.

Safe loop:

```bash
bash phases/phase-0/doctor.sh
sudo bash phases/phase-0/bootstrap.sh
bash phases/phase-0/validate.sh
```

If validation fails, fix the reported item and run the same loop again.

## Final state expected

At the end of Phase 0, the machine should have:

- Linux installed and reachable on the network
- SSH access without needing a monitor
- a predictable IP address or DHCP reservation
- an administrative user
- basic firewall enabled
- system packages updated
- sleep, suspend, and hibernation disabled
- Docker Engine installed
- Docker Compose plugin installed
- Docker usable by the admin user without sudo
- base Ektisis directories created

Do not install Gitea, LiteLLM, FreeLLMAPI, OpenHands, or orchestration services in this phase.

## Recommended operating system

Use, in this order:

1. Debian 12 or newer, minimal/server
2. Ubuntu Server LTS
3. Debian with a graphical interface, only if sleep is disabled

For a dedicated local machine, prefer Debian. For a VPS, Ubuntu Server LTS is also a good option because many providers support it well.

Avoid using a desktop-oriented system as the official base.

## Before running scripts: physical or BIOS checks

For a local headless machine, check the BIOS or UEFI if possible:

- Restore on AC Power Loss: Power On
- Virtualization, VT-x, or AMD-V: Enabled
- Wake on LAN: optional
- Secure Boot: keep enabled unless it causes driver problems later
- Above 4G Decoding: optional, useful later if GPU support is needed
- Primary Display: Auto or iGPU if available

The most important item is automatic power recovery after power loss.

For a VPS, skip this section.

## Step 0 — Start from a fresh machine

If the machine was just created or formatted, install Git first:

```bash
sudo apt-get update
sudo apt-get install -y git
```

Then clone the project:

```bash
git clone https://github.com/HumanAIWorks/ektisis.git
cd ektisis
```

This step is also repeatable if the repository already exists. In that case, do not clone again. Update it instead:

```bash
cd ektisis
git pull
```

## Step 1 — Inspect the machine

Run:

```bash
bash phases/phase-0/doctor.sh
```

This script only inspects the machine. It should not change anything.

What it checks:

- operating system family
- hostname and network detection
- SSH status
- Docker status, if Docker already exists
- Docker Compose status, if available
- disk layout

What to do after it runs:

- If there are only `OK` and `WARN` lines, continue to Step 2.
- If there is a `FAIL`, stop and fix the failure before continuing.
- A warning is not always a blocker. It often means the bootstrap script still needs to configure something.

You may run `doctor.sh` again at any time.

## Step 2 — Apply the baseline

Run:

```bash
sudo bash phases/phase-0/bootstrap.sh
```

What it does:

- updates package metadata
- installs minimal base packages
- enables SSH
- enables UFW and allows OpenSSH
- disables sleep, suspend, and hibernation targets
- installs Docker from the official Docker APT repository when Docker is missing
- removes known conflicting Docker packages before installing Docker
- configures Docker data-root at `/home/docker-data` when safe
- adds the current user to the Docker group
- creates base Ektisis directories under `~/ektisis`

Idempotent behavior:

- already installed packages are kept
- SSH is enabled again if needed
- UFW keeps existing OpenSSH rules
- masked sleep targets stay masked
- Docker installation is skipped when Docker already exists
- Docker data-root is changed only when there are no containers
- existing Ektisis directories are kept

What to do after it runs:

- If Docker was installed for the first time, close the SSH session and connect again.
- If you do not want to reconnect yet, you can try `newgrp docker`.
- After reconnecting, return to the project folder.

Example:

```bash
cd ~/ektisis
```

If the repository was cloned somewhere else, go back to that folder instead.

You may run `bootstrap.sh` again after a failure or after manually fixing something.

## Step 3 — Validate Phase 0

Run:

```bash
bash phases/phase-0/validate.sh
```

What it checks:

- OS is supported
- hostname and IP are available
- SSH is active
- Docker is active
- Docker works without sudo
- Docker Compose works
- Docker data-root is acceptable for the disk layout
- UFW is active
- OpenSSH is allowed in UFW
- sleep, suspend, and hibernation targets are disabled
- base Ektisis directories exist

What to do after it runs:

- If validation passes, continue to Step 4.
- If validation fails because Docker requires sudo, reconnect to the server and run validation again.
- If validation still fails, do not continue to Phase 1A. Fix Phase 0 first.

You may run `validate.sh` again at any time.

## Step 4 — Generate the local machine inventory

Run:

```bash
bash phases/phase-0/generate-machine-md.sh
```

This creates or rewrites a local `MACHINE.md` file with the minimum useful machine information for debugging and comparison.

Do not commit a real `MACHINE.md` from a real machine.

## Manual network step: predictable IP

For a local server, prefer DHCP reservation in the router instead of setting a static IP inside Linux.

Use the machine MAC address and reserve an IP in the router admin panel.

To find MAC addresses:

```bash
ip link
```

For a VPS, the public IP is usually assigned by the provider. No local router reservation is needed.

## Optional SSH key setup

From your main computer, create a key if you do not already have one:

```bash
ssh-keygen -t ed25519 -C "ektisis"
```

Copy it to the server:

```bash
ssh-copy-id your_user@SERVER_IP
```

Test login before changing SSH hardening settings:

```bash
ssh your_user@SERVER_IP
```

## Optional SSH hardening

Only do this after SSH key login works.

Edit SSH server config:

```bash
sudo nano /etc/ssh/sshd_config
```

Use these settings:

```txt
PermitRootLogin no
PasswordAuthentication no
PubkeyAuthentication yes
X11Forwarding no
```

Restart SSH:

```bash
sudo systemctl restart ssh
```

Before closing the current terminal, open another terminal and test SSH login again.

## Phase 0 is complete when

All of these are true:

- `validate.sh` passes
- the machine is reachable by SSH
- Docker is active
- Docker works without sudo
- Docker Compose works
- firewall allows SSH
- sleep, suspend, and hibernation are disabled
- Docker data-root is acceptable for the disk layout
- base Ektisis directories exist

When all items pass, the machine is ready for Phase 1A.

## Full command sequence

For a fresh machine:

```bash
sudo apt-get update
sudo apt-get install -y git

git clone https://github.com/HumanAIWorks/ektisis.git
cd ektisis

bash phases/phase-0/doctor.sh
sudo bash phases/phase-0/bootstrap.sh

# reconnect if Docker was installed for the first time

bash phases/phase-0/validate.sh
bash phases/phase-0/generate-machine-md.sh
```

For an existing clone:

```bash
cd ektisis
git pull
bash phases/phase-0/doctor.sh
sudo bash phases/phase-0/bootstrap.sh
bash phases/phase-0/validate.sh
```

Next phase after this is Phase 1A: run Gitea and PostgreSQL with Docker Compose.
