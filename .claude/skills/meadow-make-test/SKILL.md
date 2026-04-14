---
name: meadow-make-test
description: Run Meadow tests through repository Make targets with correct Localstack provisioning and argument forwarding. Use when working in /Users/brendan/nulib/meadow and you need to run test suites, re-run failed tests, run a single test file, or pass `mix test` flags via `ARGS` such as `--failed`, `--seed`, or file paths.
---

# Meadow Make Test

Use Make targets instead of calling `mix test` directly so environment setup and provisioning remain consistent.

## Inspect Available Targets

1. Run `make help` at repository root to view namespaced targets.
2. Run `make app-help` for app-specific targets.
3. Run `make localstack-help` for Localstack lifecycle targets.

Use this mapping:
- Root app tests: `make app-test`
- Root all tests (backend + frontend): `make app-all-test`
- App-only equivalents from `app/`: `make test`, `make all-test`
- Provisioning: `make localstack-provision`

## Test Execution Workflow

1. Start with the narrowest run that answers the request.
2. Execute from repo root unless the user explicitly asks otherwise.
3. Pass `mix test` filters through `ARGS` exactly once with shell quoting.
4. Report the executed command, pass/fail outcome, and key failure lines.

Common commands:
```bash
make app-test
make app-test ARGS="--failed"
make app-test ARGS="test/meadow/csv_metadata_update_driver_test.exs"
make app-test ARGS="test/meadow/csv_metadata_update_driver_test.exs:24"
make app-test ARGS="--seed 315411"
make app-all-test
```

## ARGS Rules

- Treat `ARGS` as direct `mix test` arguments.
- Preserve user-provided ordering and flags.
- Keep `ARGS` in double quotes when it contains spaces.
- Do not add extra escaping unless required by the shell.

Examples:
- `ARGS="--failed"`
- `ARGS="test/meadow/foo_test.exs --max-failures 1"`
- `ARGS="--seed 12345 test/meadow/foo_test.exs"`

## Failure Triage

When tests fail:
1. Surface failing test names, locations, and primary error messages.
2. Call out environment/provisioning symptoms (Localstack/S3/DB/migrations) if present.
3. Suggest the smallest rerun command first, then broader fallback.

Rerun sequence:
1. `make app-test ARGS="<specific test file or line>"`
2. `make app-test ARGS="--failed"`
3. `make app-test`

If failures indicate stale infrastructure, run:
```bash
make localstack-stop
make localstack-start
make localstack-provision
```
Then rerun the same `make app-test ARGS="..."` command.

## Output Contract

After any run, return:
1. Exact command executed.
2. Whether tests passed or failed.
3. Short list of failing tests/errors (or confirmation of zero failures).
4. Next rerun command when failures exist.
