# 21. Elasticsearch indexing

Date: 2020-01-27

## Status

Accepted

## Context

We need to push our Meadow resources to the Elasticsearch `common` index so that they can be discovered on the Digital Collections website. We also want the ability to do full text searching and faceting from within the Meadow ingest application. We investigated using Postgres through our GraphQL API, but concluded there would potentially be performance issues at scale.

## Decision

- Meadow will write to same `common` index that Donut does
  - The `source.model.application` property exists to identify source application
- Items will be indexed with a `published` `true` or `false` flag
- Requests through the `elastic-proxy` will refuse to return any unpublished items.
- For Elasticsearch requests through from the Meadow front end, the Elixir app backend will provide a plug/route and add AWS signing credentials to the request as well as filter results limiting to Meadow items only.

## Consequences

Full text searching and faceting in Meadow will be easier but the front end will now have to make requests through more than one API, increasing the complexity somewhat.
