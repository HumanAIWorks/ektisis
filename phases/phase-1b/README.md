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

Then open Gitea in your browser.

The address is usually:

```txt
http://YOUR_SERVER_IP:3000/
```

For documentation examples, this guide uses a reserved example IP:

```txt
http://203.0.113.10:3000/
```

Use your own server IP. Do not copy the example IP.

If you do not know the address, run:

```bash
bash phases/phase-1a/check-access.sh
```

The script prints the URL to try in your browser.

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

These commands confirm that Gitea is still running and reachable. The access check also prints the browser URL for Gitea.

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

## Step 3 — Open Gitea in the browser

Open a browser on your computer and go to the Gitea URL.

The URL format is:

```txt
http://YOUR_SERVER_IP:3000/
```

For example, using a documentation-only IP:

```txt
http://203.0.113.10:3000/
```

Replace the IP with your server IP. The example IP is reserved for documentation and should not be used as-is.

If you are using a local machine at home or in the office, the address may be a local network IP instead:

```txt
http://192.168.x.x:3000/
```

An IP is the address of a machine on a network. The number after `:` is the port. In this phase, Gitea uses port `3000` for the web page.

If you are not logged in, click **Sign In** and enter the administrator username and password created during Phase 1A.

## Step 4 — Create the organization in Gitea

In Gitea, use the top-right menu.

The path is:

```txt
Top-right + menu
→ New Organization
```

Depending on the language of the interface, this may appear as:

```txt
Menu + no canto superior direito
→ Nova Organização
```

Use:

```txt
Organization Name: ektisis
Visibility: Private recommended
```

Private is safer if the machine is exposed on the internet. Private means only allowed users can see the repositories.

Create the organization.

## Step 5 — Create a test repository

After creating the organization, open the `ektisis` organization page.

Then create a repository:

```txt
New Repository
```

Depending on the language of the interface, this may appear as:

```txt
Novo Repositório
```

Use:

```txt
Owner: ektisis
Repository Name: phase-1b-smoke-test
Visibility: Private recommended
Initialize repository: checked
Default branch: main
```

If the screen asks about README, choose to initialize with a README. This makes clone and push testing easier.

Create the repository.

## Step 6 — Run the Git smoke test

This step clones the test repository, creates a tiny file, commits it, and pushes it back to Gitea.

Run from the server:

```bash
bash phases/phase-1b/smoke-test-http.sh
```

The script will ask for:

- Gitea username
- Gitea password or token
- organization name
- repository name

A token is a special password created for automation. For now, using your Gitea password is acceptable for the first manual test. Later we will prefer tokens.

When asked for organization and repository, press Enter to accept the defaults if you used the recommended names.

## Expected result

At the end, the script should show:

```txt
Phase 1B smoke test completed.
```

Then open the repository in the browser and confirm that the new file exists:

```txt
phase-1b-smoke-test.txt
```

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
