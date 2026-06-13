# Phase 0 — Machine Stabilization

[Português do Brasil](./README.pt-BR.md)

Phase 0 prepares a Debian or Ubuntu machine to behave as a reliable server for Ektisis.

The goal is not to install the full platform yet. The goal is to reach the smallest reliable base for the next phase.

## Supported systems

- Debian 12+ server/minimal
- Ubuntu Server LTS

Recommended default:

- Debian 12+ for a dedicated local machine
- Ubuntu Server LTS for a VPS/cloud machine

## Start from a fresh machine

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

## Step 1 — Inspect the machine

Run:

```bash
bash phases/phase-0/doctor.sh
```

What this does:

- checks the operating system
- checks hostname and network detection
- checks SSH
- checks Docker if it already exists
- checks disk layout

What to do after it runs:

- If there are only `OK` and `WARN` lines, continue to Step 2.
- If there is a `FAIL`, stop and fix the failure before continuing.
- Warnings are not always blockers. They show what the bootstrap may need to fix.

## Step 2 — Apply the baseline

Run:

```bash
sudo bash phases/phase-0/bootstrap.sh
```

What this does:

- installs base packages
- enables SSH
- enables UFW and allows OpenSSH
- disables sleep, suspend, and hibernate targets
- installs Docker when Docker is missing
- configures Docker data-root at `/home/docker-data` when safe
- adds the current user to the Docker group
- creates local Ektisis folders under `~/ektisis`

What to do after it runs:

- If Docker was installed for the first time, close the SSH session and connect again.
- If you prefer not to reconnect yet, you can try `newgrp docker`.
- After reconnecting, return to the project folder.

Example:

```bash
cd ~/ektisis
```

If the repository is not in `~/ektisis`, go back to the folder where you cloned it.

## Step 3 — Validate Phase 0

Run:

```bash
bash phases/phase-0/validate.sh
```

What this does:

- confirms the OS is supported
- confirms SSH is active
- confirms Docker is active
- confirms Docker works without sudo
- confirms Docker Compose works
- checks if Docker data-root is acceptable for the disk layout
- confirms firewall baseline
- confirms sleep/suspend/hibernate are disabled

What to do after it runs:

- If validation passes, continue to Step 4.
- If validation fails because Docker requires sudo, reconnect to the server and run validation again.
- If validation still fails, do not continue to Phase 1. Fix Phase 0 first.

## Step 4 — Generate the local machine inventory

Run:

```bash
bash phases/phase-0/generate-machine-md.sh
```

What this does:

- creates a local `MACHINE.md` file
- records the minimum useful machine information for debugging and comparison

This file is local only and should not be committed with real machine data.

## Phase 0 is complete when

All of these are true:

- `validate.sh` passes
- SSH is active
- Docker is active
- Docker works without sudo
- Docker Compose works
- the firewall allows SSH
- sleep, suspend, and hibernate are disabled
- Docker data-root is acceptable for the machine disk layout

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
