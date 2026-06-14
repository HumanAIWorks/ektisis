# Ektisis

[Português do Brasil](./README.pt-BR.md)

Ektisis is a local or VPS-hosted software factory for AI-assisted SaaS development.

The goal is to install a small set of Docker-based tools that make this flow possible:

```txt
human defines a task
→ AI agent changes code in a repository
→ automated checks validate the change
→ human reviews and approves
→ approved code can be merged and deployed
```

## Project plan

The current approved plan is documented here:

[docs/plan.md](./docs/plan.md)

This plan is the source of truth before adding new phases.

## Current focus

The project is moving from machine stabilization into the minimum toolchain needed to reach the first AI-made code change.

Immediate sequence:

```txt
Phase 0 — Machine
Phase 1 — Gitea
Phase 2 — LiteLLM + FreeLLMAPI
Phase 3 — OpenHands
Phase 4 — First AI-generated code change
```

Validation belongs inside the phase that owns the tool. A separate public phase should not exist only to prove a sub-behavior.

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

Install the required tool, validate it automatically, clean temporary validation resources, and move to the next required tool.
