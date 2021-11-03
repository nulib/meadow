# 27. Semantic Versioning

Date: 2021-03-03

## Status

Accepted

## Context

Simplify versioning.

Supersedes [24. Version Management](0024-version-management.md)

## Decision

When merging from staging to main:

- Update the `@app_version` attribute in `mix.exs` on the staging branch:
  - Major version: Backward-incompatible database and/or API changes
  - Minor version: New features or backward-compatible database and/or API changes
  - Point version: All other changes
- PR staging to main
- After CircleCI is finished building and deploying the new version, it will
  automatically tag the correct revision with the version number and push
  the tag to Github

## Consequences

- Tagging is consistent and easy
