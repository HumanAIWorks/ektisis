# Ektisis Phase 1B — Gitea baseline configuration

Phase 1B validates that the Gitea instance from Phase 1A is usable as the first Git server for the factory.

This phase is intentionally small. It does not configure HTTPS, a domain name, CI/CD, runners, or AI agents yet.

## Goal

At the end of this phase, you should have:

- a first organization in Gitea
- a first test repository
- a successful Git clone from Gitea
- a successful commit
- a successful push back to Gitea

A repository is a project folder tracked by Git. Git is the tool used to store code history.

An organization is a group inside Gitea where related repositories can live together.

## Run order

Follow this order from the repository root.

First, make sure Phase 1A is still healthy:

```bash
bash phases/phase-1a/validate.sh
bash phases/phase-1a/check-access.sh
```

Then validate that Phase 1B can run:

```bash
bash phases/phase-1b/validate.sh
```

Then create the organization and repository in the browser.

Recommended names:

```txt
Organization: ektisis
Repository: phase-1b-smoke-test
```

Then run the Git smoke test:

```bash
bash phases/phase-1b/smoke-test-http.sh
```

A smoke test is a small test that confirms the basic flow works before building more things on top.

## Before you start

Phase 1A must already be complete, and you need a Gitea administrator user created in the browser.

If Phase 1A is not complete yet, go back to:

```txt
phases/phase-1a/README.md
```

## Step 1 — Confirm Phase 1A

From the server:

```bash
bash phases/phase-1a/validate.sh
bash phases/phase-1a/check-access.sh
```

These commands confirm that Gitea is still running and reachable.

## Step 2 — Validate Phase 1B prerequisites

From the server:

```bash
bash phases/phase-1b/validate.sh
```

The script checks:

- Phase 1A is still healthy
- Gitea answers locally
- the Git command exists
- the runtime test directory exists

## Step 3 — Create the organization in Gitea

Open Gitea in your browser.

Then:

```txt
Top-right + menu
→ New Organization
```

Use:

```txt
Organization Name: ektisis
Visibility: Public or Private
```

For now, either visibility is fine. Private is safer if the machine is exposed on the internet.

## Step 4 — Create a test repository

Inside the `ektisis` organization:

```txt
New Repository
```

Use:

```txt
Repository Name: phase-1b-smoke-test
Visibility: Private recommended
Initialize repository: checked
Default branch: main
```

If the screen asks about README, choose to initialize with a README. This makes clone and push testing easier.

## Step 5 — Run the Git smoke test

This step clones the test repository, creates a tiny file, commits it, and pushes it back to Gitea.

Run:

```bash
bash phases/phase-1b/smoke-test-http.sh
```

The script will ask for:

- Gitea username
- Gitea password or token
- organization name
- repository name

A token is a special password created for automation. For now, using your Gitea password is acceptable for the first manual test. Later we will prefer tokens.

## Expected result

At the end, the script should show:

```txt
Phase 1B smoke test completed.
```

Then open the repository in the browser and confirm that the new file exists.

## If authentication fails

If Git asks for a username/password and fails, check:

- the username is your Gitea username, not the Linux username
- the password is the Gitea password, not the PostgreSQL password
- the repository name is correct
- the organization name is correct

PostgreSQL is the database behind Gitea. Its password is not used for Git clone or push.

## If the browser works but Git clone fails

Run:

```bash
bash phases/phase-1a/check-access.sh
```

If Gitea is reachable in the browser but clone still fails, copy the exact Git error and inspect the repository clone URL in Gitea.

## Completion criteria

Phase 1B is complete when:

- organization `ektisis` exists, or another chosen organization exists
- repository `phase-1b-smoke-test` exists, or another chosen test repository exists
- clone via HTTP works
- commit works
- push works
- the pushed file appears in the Gitea browser UI
