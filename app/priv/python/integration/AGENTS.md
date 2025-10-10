# Repository Guidelines

## Project Structure & Module Organization
- Elixir app: `lib/` (source), `test/` (ExUnit), `config/` (runtime), `mix.exs` (project).
- Python agents: `priv/python/agent/` (package `meadow-metadata-agent`), `priv/python/integration/` (local runner, `pyproject.toml`, `uv.lock`).
- Build artifacts: `_build/`, deps: `deps/`. Do not edit generated content.

## Build, Test, and Development Commands
- Install deps (Elixir): `mix deps.get` — fetch Hex deps.
- Compile (Elixir): `mix compile` — build the app.
- Test (Elixir): `mix test` — run ExUnit; add `--cover` for coverage.
- REPL (Elixir): `iex -S mix` — interactive dev; try `MeadowAI.query("hello", context: %{})`.
- Python setup: `cd priv/python/integration && uv sync` — create `.venv` and install `meadow-metadata-agent` and deps.
- Python run example: `uv run python -c "from meadow_metadata_agent.execute import query_claude_sync; print(query_claude_sync('ping','{}'))"`.

## Coding Style & Naming Conventions
- Elixir: 2‑space indentation, pipe-first style where clear; run `mix format` (configured via `.formatter.exs`). Modules under `MeadowAI.*`.
- Python (3.11+): PEP 8, 4‑space indentation, use type hints where reasonable. Keep package name `meadow_metadata_agent` and modules snake_case.

## Testing Guidelines
- Framework: ExUnit (`test/*_test.exs`). Name files `*_test.exs` and use descriptive test names.
- Run: `mix test` locally and in CI. Aim to cover happy paths and error handling in `MeadowAI.MetadataAgent`.
- Optional coverage: `mix test --cover` to gauge unit coverage.

## Commit & Pull Request Guidelines
- Commits: imperative mood, concise subject (max ~72 chars). Group logical changes; include context in body and reference issues (e.g., `Closes #123`).
- PRs: clear description, rationale, and screenshots/logs if behavior changes. Link issues, note breaking changes, and add test updates.
- CI hygiene: ensure `mix compile`, `mix test`, and Python `uv sync` + sample run succeed.

## Security & Configuration Tips
- Configuration uses environment variables for model backends: `AWS_BEARER_TOKEN_BEDROCK`, `AWS_REGION`, `CLAUDE_CODE_USE_BEDROCK`, `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_SESSION_TOKEN`.
- Never commit secrets. Use local env vars or a secure secrets manager. Validate changes without real keys when possible.
