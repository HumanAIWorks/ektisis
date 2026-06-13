# Ektisis

[Português do Brasil](./README.pt-BR.md)

Ektisis turns human intent into working software with AI assistance.

## Current focus

The project starts with **Phase 0**: scripts that diagnose, stabilize, and validate a Linux machine so it can behave as a reliable server for an AI-assisted software creation environment.

## Supported operating systems

Initial support targets:

- Debian 12+ server/minimal
- Ubuntu Server LTS

Recommended default:

- **Debian 12+** for a stable local server or dedicated machine
- **Ubuntu Server LTS** for VPS/cloud providers where Ubuntu images are better supported

## Phase 0 workflow

```bash
./phases/phase-0/doctor.sh
./phases/phase-0/bootstrap.sh
./phases/phase-0/validate.sh
```

## Principle

Before installing a software factory, prove that the machine can act like a server.
