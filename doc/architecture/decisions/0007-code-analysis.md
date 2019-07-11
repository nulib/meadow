# 7. code-analysis

Date: 2019-06-28

## Status

Accepted

## Context

We need to make sure we adhere to our own designated code quality best practices.

## Decision

Use a code analysis tool (specifically, [credo](http://credo-ci.org/) for Elixir
and [prettier](https://prettier.io/) for JavaScript).

## Consequences

Code style violations will cause build failures.
