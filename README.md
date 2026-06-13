# Ektisis

[Português do Brasil](./README.pt-BR.md)

Ektisis turns human intent into working software with AI assistance.

## Current focus

The project starts with Phase 0: scripts that prepare and validate a Linux machine so it can behave as a reliable server for an AI-assisted software creation environment.

## Supported operating systems

- Debian 12+ server/minimal
- Ubuntu Server LTS

Recommended default:

- Debian 12+ for a stable local server or dedicated machine
- Ubuntu Server LTS for VPS/cloud providers where Ubuntu images are better supported

## Start on a fresh machine

Run this first on a new Debian or Ubuntu machine:

```bash
sudo apt-get update
sudo apt-get install -y git

git clone https://github.com/HumanAIWorks/ektisis.git
cd ektisis
```

Then follow the Phase 0 guide:

```bash
cat phases/phase-0/README.md
```

Or open it here:

[Phase 0 — Machine Stabilization](./phases/phase-0/README.md)

## Principle

Start with the smallest possible working base. Add only what is required to make the machine ready for the next phase.
