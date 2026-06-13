# Execution contract

This project treats the repository as the source of truth for executable steps.

## Rule

If a person needs to run a command on a machine, click something in a stack component, change a setting, or follow a manual operational step, that step must be documented in the Ektisis repository before it is treated as official.

The chat can be used for:

- planning
- analysis
- troubleshooting
- deciding the next change
- explaining failures

The repository must contain:

- commands to run
- expected outputs
- manual browser steps
- configuration values to use
- validation criteria
- troubleshooting paths

## Public documentation safety

Public documentation must use placeholders or reserved documentation examples.

Do not publish real values such as:

- real public IP addresses
- real local IP addresses
- real hostnames
- real local usernames
- passwords
- tokens
- private keys
- real runtime logs with environment-specific identifiers

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

## Before executing a phase

Before running a phase, update the repository and read the phase README:

```bash
git pull
cat phases/PHASE_NAME/README.md
```

Then follow the README, not ad hoc chat instructions.

## Before publishing or recreating the repository

Run:

```bash
bash scripts/check-public-docs.sh
```

This script is not a complete security scanner. It is a guardrail for common accidental exposures.

Manual review is still required before publishing or recreating a public repository.
