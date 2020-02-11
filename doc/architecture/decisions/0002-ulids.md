# 2. ulids

Date: 2019-06-25

## Status

Superceded by [23. uuids](0023-uuids.md)

## Context

Postgres can autoincrement identifiers for database tables. By default this is an integer. 

## Decision

We decided to use [ULID](https://github.com/ulid/spec)'s for all database id's.  Serial integers present potential problems with scaling and concurrency. Unlike UUID's ULID's are lexicographically (i.e., alphabetically) sortable as the first 48 bits of the identifier contain a UNIX timestamp.

## Consequences

This will require a little more customization of our Postgres schemas upfront, and there are a couple known drawbacks of ULID's.
 - If exposing the timestamp is a bad idea for your application, ULIDs may not be the best option.
 - The sort by ulid approach may not work if you need sub-millisecond accuracy.
 - According to the internet, some ULID implementations aren't bulletproof.
