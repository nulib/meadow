# 29. npm

Date: 2021-11-03

## Status

Accepted

## Context

The latest upgrade of Yarn has introduced issues that we're finding difficult to overcome.

Supersedes [11. Yarn](0011-yarn.md)

## Decision

Switch back to `npm` instead of `yarn` in all dev, test, and build environments.

## Consequences

The instructions have changed, but overall the complexity involved in installing and maintaining 
meadow's JavaScript dependencies should be about the same.
