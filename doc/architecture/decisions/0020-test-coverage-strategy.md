# 20. test-coverage-strategy

Date: 2020-01-13

## Status

Accepted

## Context

Looking at our waning test coverage, we decided we needed a review of our test coverage
strategy, especially a consideration of which parts of the project should be included
in test coverage reports.

## Decision

* If low-level code is consistently coming up as uncovered, first check to
  see if anything in the project is actually using that code. If not, remove
  it.
* Continue to write/run front end tests as needed, but remove them from the
  coverage report.
* Remove mocks, views, and GraphQL types from the coverage report.

## Consequences

This change allows us to focus our coverage goals (and build success/failure)
on the essentials without sacrificing the flexibility to write tests for
whatever we deem necessary (even if it's outsize the scope of required
coverage).
