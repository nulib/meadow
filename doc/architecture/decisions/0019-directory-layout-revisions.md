# 19. Directory Layout Revisions

Date: 2019-12-13

## Status

Accepted

Amends [15. Phoenix Context Organization](0015-phoenix-context-organization.md)

## Context

The code organization we agreed upon in [15. Phoenix Context Organization](0015-phoenix-context-organization.md), has become a bit unweildy in practice - specifically the nested schema module names and confusion around function placement within the hierarchy.

## Decision

Put schemas inside a `schemas` directory at the top level of the context and place all schemas inside. Flatten other files at the top level alongside the schemas.

## Consequences

We might need to amend further, but a move in the right direction.
