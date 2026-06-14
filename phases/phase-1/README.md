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

## Run

From the repository root:

```bash
bash phases/phase-1/run.sh
```

That is the public entrypoint for this phase.

## What run.sh does

```txt
validate Phase 0
start Gitea + PostgreSQL
validate Gitea + PostgreSQL
check Gitea access
run temporary Git clone/commit/push smoke test
clean temporary Git smoke test resources
```

## Current implementation note

This unified phase currently reuses implementation scripts from:

```txt
phases/phase-1a
phases/phase-1b
```

Those directories are internal implementation details while the phase is being consolidated.

The public interface for Phase 1 is only:

```txt
phases/phase-1/README.md
phases/phase-1/run.sh
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
