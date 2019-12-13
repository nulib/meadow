# 15. Phoenix Context Organization

Date: 2019-09-11

## Status

Accepted

Amended by [19. Directory Layout Revisions](0019-directory-layout-revisions.md)

## Context

Our Phoenix Contexts are becoming bloated. We need some organizational pattern to keep things modular.

## Decision

We've decided to use the rules described here: [A Proposal for Some New Rules for Phoenix Contexts](http://devonestes.herokuapp.com/a-proposal-for-context-rules)

1. Resources have Schema files, and those contain only schema definitions, type definitions, validations and changeset functions
2. Every Schema has its own Secondary Context
3. The only place you use your Repos is in a Secondary Context, and only for the associated resource
4. Primary Contexts define higher level ideas in your application, and most interactions between resources will take place there

## Consequences

We will need to refactor a bit right now but this should give us a good pattern moving forward.
