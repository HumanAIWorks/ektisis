# Ektisis Phase 1B — Gitea baseline configuration

This guide is the official step-by-step process for Phase 1B.

Follow it from top to bottom.

Phase 1B proves that the Gitea instance from Phase 1A can be used as the first Git server for the factory.

This phase does not configure HTTPS, a domain name, CI/CD, runners, or AI agents yet.

## What Phase 1B proves

At the end of this phase, Gitea must support this basic Git flow:

```txt
create organization
→ create repository
→ clone repository
→ commit a file
→ push the file back
→ confirm the file in the browser
```

A repository is a project folder tracked by Git.

An organization is a group inside Gitea where related repositories can live together.

A smoke test is a small test that confirms the basic flow works before building more things on top.

## Step 1 — Update the local copy of Ektisis

Run this on the server from the repository directory.

```bash
cd ~/ektisis
git pull
```

Why this step exists:

- it makes sure you are using the latest scripts and documentation
- it prevents following old instructions from a previous commit

Expected result:

```txt
Already up to date.
```

or Git downloads newer files.

Then keep following this same README.

## Step 2 — Check public documentation safety

Run:

```bash
bash scripts/check-public-docs.sh
```

Why this step exists:

- this repository is public during development
- the check helps catch accidental exposure of real environment values before continuing

Expected result:

```txt
Public documentation exposure check passed.
```

If this step fails, stop here. Fix the reported file in the repository, pull the fix, and run this step again.

Then return to Step 2.

## Step 3 — Confirm Phase 1A is still healthy

Run:

```bash
bash phases/phase-1a/validate.sh
bash phases/phase-1a/check-access.sh
```

Why this step exists:

- Phase 1B depends on the Gitea and PostgreSQL services created in Phase 1A
- this confirms the services are still running before testing Git operations
- the access check prints the browser URL for Gitea

Expected result:

```txt
Phase 1A validated. Gitea + PostgreSQL are running.
```

The access check should also say that Gitea responds inside the machine.

If this step fails, follow the troubleshooting document suggested by the script output.

Common links:

```txt
docs/troubleshooting/oci.md
docs/troubleshooting/local-network.md
docs/troubleshooting/generic-vps.md
```

After fixing the problem, return to Step 3.

## Step 4 — Validate Phase 1B prerequisites

Run:

```bash
bash phases/phase-1b/validate.sh
```

Why this step exists:

- it confirms Git exists on the server
- it confirms Gitea still responds locally
- it prepares the runtime workspace used by the smoke test

Expected result:

```txt
Phase 1B validation passed. Ready for the Git smoke test.
```

If this step fails, read the script output, fix the reported issue, and return to Step 4.

## Step 5 — Open Gitea in the browser

Open a browser on your computer.

Use the URL printed by Step 3.

The URL format is:

```txt
http://YOUR_SERVER_IP:3000/
```

For documentation examples only, this guide may use:

```txt
http://203.0.113.10:3000/
```

Do not copy the example IP. Use your own server IP.

Why this step exists:

- organization and repository creation are manual in this phase
- later phases may automate this with the Gitea API, but Phase 1B keeps the baseline visible and simple

Expected result:

- the Gitea web interface opens
- you can sign in with the administrator account created during Phase 1A

If the browser does not open Gitea, return to Step 3 and follow the troubleshooting link suggested by `check-access.sh`.

## Step 6 — Sign in to Gitea

In the Gitea browser page, click:

```txt
Sign In
```

Depending on the interface language, this may appear as:

```txt
Entrar
```

Enter the administrator username and password created during Phase 1A.

Why this step exists:

- the next steps create an organization and repository
- those actions require an authenticated Gitea user

Expected result:

- you are logged in
- the top-right user menu appears

If sign-in fails, confirm you are using the Gitea user password, not the PostgreSQL password and not the Linux password.

Then return to Step 6.

## Step 7 — Create the organization

In Gitea, use the top-right menu.

Click:

```txt
Top-right + menu
→ New Organization
```

Depending on the interface language, this may appear as:

```txt
Menu + no canto superior direito
→ Nova Organização
```

Fill in:

```txt
Organization Name: ektisis
Visibility: Private recommended
```

Then create the organization.

Why this step exists:

- factory repositories should live under an organization, not under a personal user
- this gives us a stable namespace for future automation

Expected result:

- an organization named `ektisis` exists in Gitea
- the organization page opens after creation

If the organization already exists, open it and continue to Step 8.

## Step 8 — Create the smoke test repository

Inside the `ektisis` organization page, create a new repository.

Click:

```txt
New Repository
```

Depending on the interface language, this may appear as:

```txt
Novo Repositório
```

Fill in:

```txt
Owner: ektisis
Repository Name: phase-1b-smoke-test
Visibility: Private recommended
Initialize repository: checked
Default branch: main
```

If the screen asks about README, choose to initialize with a README.

Then create the repository.

Why this step exists:

- the smoke test needs a repository to clone
- initializing with README avoids testing against an empty repository

Expected result:

- the repository page opens
- the repository path is under the organization `ektisis`
- the repository name is `phase-1b-smoke-test`

The browser URL should have this shape:

```txt
http://YOUR_SERVER_IP:3000/ektisis/phase-1b-smoke-test
```

If the repository was created under your personal user instead of the organization, create it again under the `ektisis` organization.

Then return to Step 8 and confirm the repository path.

## Step 9 — Run the Git smoke test

Return to the server terminal and run:

```bash
bash phases/phase-1b/smoke-test-http.sh
```

The script asks for:

```txt
Gitea username
Gitea password or token
Organization
Repository
```

Use your Gitea username and password.

When asked for organization and repository, press Enter to accept the defaults if you used the recommended names.

Why this step exists:

- it proves clone works
- it proves local commit works
- it proves push back to Gitea works

Expected result:

```txt
Phase 1B smoke test completed.
```

If the script says `Repository not found`, go to the troubleshooting section `Repository not found`, then return to Step 9.

If authentication fails, go to the troubleshooting section `Authentication failed`, then return to Step 9.

## Step 10 — Confirm the pushed file in the browser

Open the test repository in Gitea.

The repository URL shape is:

```txt
http://YOUR_SERVER_IP:3000/ektisis/phase-1b-smoke-test
```

Look for this file:

```txt
phase-1b-smoke-test.txt
```

Why this step exists:

- the terminal can say push succeeded, but the browser confirms Gitea stored the change

Expected result:

- the file appears in the repository file list
- opening the file shows the smoke test timestamp

If the file does not appear, refresh the page. If it still does not appear, return to Step 9 and copy the exact script output for troubleshooting.

## Troubleshooting: Repository not found

Use this section only if Step 9 fails with:

```txt
Repository not found
```

Check in the browser:

```txt
Organization exists: ektisis
Repository exists inside that organization: phase-1b-smoke-test
Repository was initialized with README
```

The repository URL should have this shape:

```txt
http://YOUR_SERVER_IP:3000/ektisis/phase-1b-smoke-test
```

Common causes:

- the organization was not created
- the repository was not created
- the repository was created under a personal user instead of the organization
- the repository name has a typo
- the logged-in user does not have permission to read the repository

Fix the issue in Gitea.

Then return to Step 9.

## Troubleshooting: Authentication failed

Use this section only if Step 9 fails with an authentication error.

Check:

- the username is your Gitea username, not the Linux username
- the password is the Gitea password, not the PostgreSQL password
- the user has access to the repository

PostgreSQL is the database behind Gitea. Its password is not used for Git clone or push.

Fix the issue.

Then return to Step 9.

## Phase 1B completion criteria

Phase 1B is complete when all items are true:

- Phase 1A validation passes
- Phase 1B validation passes
- organization `ektisis` exists, or another chosen organization exists
- repository `phase-1b-smoke-test` exists, or another chosen test repository exists
- clone via HTTP works
- commit works
- push works
- the pushed file appears in the Gitea browser UI
