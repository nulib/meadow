# 10. dependencies

Date: 2019-07-10

## Status

Accepted

## Context

We want to guard against out-of-date dependencies, especially those with security issues.

## Decision

Use github's [dependabot](https://dependabot.com/) to track dependencies and generate
pull requests to stay up to date.

## Consequences

Dependabot is issuing PRs against an intermediate branch, `dependencies`. This branch will 
have to be merged into `deploy/staging` periodically, and have `deploy/staging` back-merged 
into it as needed.
