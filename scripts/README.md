# Deterministic Checks

Single entrypoint:

```bash
./scripts/check.sh
```

`check.sh` runs:

1. `check-md.sh`
2. `check-tests-unchanged.sh`
3. `check-project.sh` (project-specific extension point)

## Test Immutability (Detection)

This repo uses a committed SHA-256 manifest at `tests/.manifest.sha256`.

- `./scripts/check-tests-unchanged.sh` fails if anything under `tests/` differs from the manifest.
- If a test change is intentional, update the manifest:

```bash
./scripts/update-test-manifest.sh
```

Commit both the test changes and the updated manifest together.

This mechanism provides deterministic detection of test changes. It does not create absolute immutability against privileged repository writes.

## Run On Every Commit (Optional)

This repo includes a git hook at `githooks/pre-commit`.

Enable it locally:

```bash
git config core.hooksPath githooks
```
