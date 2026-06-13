# Ektisis Phase 1B — Automated Gitea Git flow check

This guide is the official step-by-step process for Phase 1B.

Follow it from top to bottom.

Phase 1B proves that the Gitea instance from Phase 1A can be used as a Git server by an automated process.

This phase does not configure HTTPS, a domain name, CI/CD, runners, AI agents, or real project repositories yet.

## What Phase 1B proves

The phase script must prove this temporary flow:

```txt
validate Phase 1A
→ validate Phase 1B prerequisites
→ create temporary organization
→ create temporary repository
→ clone repository
→ commit a file
→ push the file back
→ remove temporary repository
→ remove temporary organization
→ remove temporary local clone
```

The temporary organization and repository exist only to prove that Gitea works.

They are not part of the final factory workspace.

A repository is a project folder tracked by Git.

An organization is a group inside Gitea where related repositories can live together.

A smoke test is a small test that confirms the basic flow works before building more things on top.

## Step 1 — Run the automated Phase 1B check

Run this from the Ektisis repository directory on the server:

```bash
bash phases/phase-1b/run.sh
```

Why this step exists:

- it checks that Phase 1A is still working
- it checks that Phase 1B prerequisites are available
- it validates Gitea through the API and Git
- it avoids leaving manual test organizations or repositories behind

The script asks for:

```txt
Gitea username
Gitea password or token
```

Use a Gitea user that can create organizations and repositories.

Expected result:

```txt
Phase 1B automated smoke test passed.
```

The script should also report that it cleaned up temporary resources.

## What the script creates temporarily

The script creates names similar to:

```txt
Organization: ektisis-smoke-<run-id>
Repository: git-flow-check
File: phase-1b-smoke-test.txt
```

These are validation artifacts only.

They should be removed automatically before the script exits.

## If Phase 1A validation fails

The script stops if Phase 1A is not healthy.

Follow Phase 1A documentation:

```txt
phases/phase-1a/README.md
```

Then run Phase 1B again:

```bash
bash phases/phase-1b/run.sh
```

## If browser or network access fails

The script uses Phase 1A access checks.

If access fails, follow the troubleshooting document suggested by the script or by the access check.

Common links:

```txt
docs/troubleshooting/oci.md
docs/troubleshooting/local-network.md
docs/troubleshooting/generic-vps.md
```

After fixing the problem, run Phase 1B again:

```bash
bash phases/phase-1b/run.sh
```

## If Gitea authentication fails

Check:

- the username belongs to Gitea, not Linux
- the credential belongs to Gitea, not PostgreSQL
- the user can create organizations
- the user can create repositories

Then run Phase 1B again:

```bash
bash phases/phase-1b/run.sh
```

## If cleanup is incomplete

The script tries to remove:

```txt
- temporary repository
- temporary organization
- temporary local clone
```

If the script warns that cleanup did not complete automatically, open Gitea in the browser and remove the temporary organization shown in the script output.

Only remove organizations with the temporary smoke-test prefix used by the script.

Do not remove real organizations or real repositories.

## Phase 1B completion criteria

Phase 1B is complete when all items are true:

- Phase 1A validation passes
- Phase 1B prerequisite validation passes
- temporary organization creation works
- temporary repository creation works
- clone via HTTP works
- commit works
- push works
- temporary repository cleanup works
- temporary organization cleanup works
- temporary local clone cleanup works

When all items pass, Gitea is ready to be used by later automated development phases.
