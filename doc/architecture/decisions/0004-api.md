# 4. api

Date: 2019-06-28

## Status

Superceded by [13. Use GraphQL for api](0013-use-graphql-for-api.md)

## Context

We discussed options for the architecutre/tooling of our API including a JSON/REST API, GraphQL API. 

## Decision

We decided to implement a JSON API documented with [OpenAPI](https://swagger.io/docs/specification/about/) (formerly Swagger), using the OpenAPI 3.0 specification. We think that since GraphQL would be an additional learning curve, for now, it is better to stick with REST and enhance with GraphQL in the future if desired. 

## Consequences

OpenAPI will help us design, build and document our API.
