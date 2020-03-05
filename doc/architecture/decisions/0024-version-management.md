# 24. Version Management

Date: 2020-03-05

## Status

Accepted

## Context

Meadow has been on version 0.1.0 since it was created. We need an easy way to update the
version in `mix.exs` and update git tags as necessary.

## Decision

- Add a Mix task, `mix meadow.version X.Y.Z`, that will:
  - Update the version string in `mix.exs` to the given X.Y.Z`
  - Commit `mix.exs`
  - Create a new git tag `vX.Y.Z`
- _After_ a merge to staging that merits a version change, one developer should:
  - Check out and pull `deploy/staging`
  - Run `mix meadow.version NEW_VERSION`
  - Push changes and tags with `git push --tags deploy/staging`

## Consequences

- Updating the Meadow version is easy
- Tags stay in sync
