# Phase 0 — Machine Stabilization

[Português do Brasil](./README.pt-BR.md)

Phase 0 prepares a Debian or Ubuntu machine to behave as a reliable server for Ektisis.

## Scripts

- `doctor.sh`: checks the current machine state without changing it.
- `bootstrap.sh`: installs and configures the baseline.
- `validate.sh`: confirms whether Phase 0 is complete.
- `generate-machine-md.sh`: generates a local machine inventory.

## Supported systems

- Debian 12+ server/minimal
- Ubuntu Server LTS

Debian is the preferred default for a dedicated local machine. Ubuntu Server LTS is a good default for VPS/cloud machines.
