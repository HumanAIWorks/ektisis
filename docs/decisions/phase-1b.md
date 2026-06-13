# Phase 1B decision — Automated Gitea Git flow check

## Status

Completed.

## Decision

Phase 1B validates Gitea through a fully automated temporary Git flow.

The official Phase 1B entrypoint is:

```bash
bash phases/phase-1b/run.sh
```

## What the phase validates

The phase script verifies that the Gitea service created in Phase 1A can be used as a Git server by an automated process.

It validates:

- Phase 1A services are healthy
- Phase 1B prerequisites are available
- a temporary Gitea user can be created
- a temporary Gitea organization can be created
- a temporary Gitea repository can be created
- a repository can be cloned over HTTP
- a file can be committed locally
- a commit can be pushed back to Gitea
- temporary validation resources are removed at the end

## Cleanup expectation

Phase 1B must not leave test organizations, test repositories, test users, or local test clones behind when it succeeds.

The script removes:

- the temporary repository
- the temporary organization
- the temporary Gitea user
- the temporary local clone

## Scope boundaries

Phase 1B does not configure:

- HTTPS
- a domain name
- CI/CD
- runners
- AI agents
- permanent project organizations
- permanent project repositories

Those belong to later phases.

## Notes

The first manual run of Phase 1B was useful as discovery, but the official phase flow is now automated and disposable.

This keeps the installation path suitable for less technical users and prepares the project for a future top-level installer that calls phase scripts in order.
