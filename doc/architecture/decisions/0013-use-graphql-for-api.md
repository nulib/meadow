# 13. Use GraphQL for api

Date: 2019-08-14

## Status

Accepted

Supercedes [4. api](0004-api.md)

## Context

GraphQL is a different way to think about APIs and can overcome some of the shortcomings of REST such as overfetching/underfetching, inflexibility, and also provides greater in depth analysis.

## Decision

We have agreed to change our API from REST documented with OpenApi to GraphQL.

## Consequences

This will allow us more flexibility for rapid iterations on the front end, and easier maintenance and evolution of our API. We also think the graph-like nature of GraphQL is well suited to the needs of our domain models. We may have to address some of the common challenges with GraphQL such as caching, rigidness of queries and monitoring.
