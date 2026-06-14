# Phase 1 — Gitea

Phase 1 installs and validates the Git server stack used by Ektisis.

This phase owns:

```txt
Gitea
PostgreSQL for Gitea
Git smoke test
```

PostgreSQL is included here because it is a Gitea dependency.

The Git smoke test is included here because it validates that Gitea is actually usable as a Git server.

## Current status

This directory is the unified Phase 1 entrypoint.

It reuses the already validated implementation from:

```txt
phases/phase-1a
phases/phase-1b
```

Those older directories are implementation details until the cleanup/move is completed.

## Run

From the repository root:

```bash
bash phases/phase-1/run.sh
```

## Validate

```bash
bash phases/phase-1/validate.sh
```

## What run.sh does

```txt
validate Phase 0
start Gitea + PostgreSQL
validate Gitea + PostgreSQL
check Gitea access
run temporary Git clone/commit/push smoke test
clean temporary Git smoke test resources
```

## Completion criteria

Phase 1 is complete when:

```txt
Gitea is running
PostgreSQL is running
Gitea responds over HTTP
Gitea can create temporary validation resources
Git clone works
Git commit works
Git push works
temporary validation resources are removed
```

## Next implementation step inside Phase 1

Add Gitea Actions Runner to this phase.

The runner belongs to Phase 1 because it is part of the Gitea-based source-control and validation stack.
