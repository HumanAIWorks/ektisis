# Execution contract

This project treats the repository as the source of truth for executable steps.

## Rule

If a person needs to run a command on a machine, click something in a stack component, change a setting, or follow a manual operational step, that step must be documented in the Ektisis repository before it is treated as official.

The chat can be used for planning, analysis, troubleshooting, deciding the next change, and explaining failures.

The repository must contain commands, expected outputs, manual browser steps, configuration values, validation criteria, and troubleshooting paths.

## Documentation style

Operational documentation must be complete, but not complex.

Each phase README must be a linear step-by-step guide that a person can follow from top to bottom.

Avoid structures that interrupt the flow:

- a separate `Before you start` section after the guide has already begun
- a high-level run order followed later by a different detailed order
- instructions like `create the repository in the browser` without explaining how to open the service and what to click

If something is required before the main work, it must be Step 1.

Each step should explain:

- what will be done
- why it is being done
- the exact command or browser action
- the expected result

Troubleshooting should work like a short detour:

1. stop the current step
2. follow the linked troubleshooting section or document
3. return to the step that failed
4. continue from the next step

The reader should never need to guess which README, script, screen, URL, or command is the current source of truth.

## Tutorial flow versus validation flow

Public tutorials are for a person starting from a known version of the repository and following it from the beginning.

Do not make repository update commands part of normal phase execution.

Updating the local clone is part of the development and validation loop used while Ektisis is being built. It is not a normal user step inside each phase.

A phase README should assume the user already has the repository available from the initial setup path. If a later update mechanism is needed, it should be designed explicitly in a future phase instead of being scattered through the docs.

Commands in public tutorials should avoid depending on the reader being in a hidden or ambiguous directory. Prefer commands that either say exactly which directory they must be run from, or use paths that make the location clear.

Do not force a full rewrite of older docs only for path style, but new and revised docs should follow this rule.

## Public documentation safety

Public documentation must use placeholders or reserved documentation examples.

Do not publish real environment values such as real IP addresses, real hostnames, real local usernames, real credentials, or real runtime logs with environment-specific identifiers.

Use placeholders instead:

```txt
YOUR_SERVER_IP
LOCAL_IP
your-user
your-vcn
your-public-subnet
```

For documentation-only public IP examples, use reserved documentation ranges such as:

```txt
203.0.113.10
```

## Before publishing or recreating the repository

Run:

```bash
bash scripts/check-public-docs.sh
```

This script is not a complete security scanner. It is a guardrail for common accidental exposures.

Manual review is still required before publishing or recreating a public repository.
