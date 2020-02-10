# 23. uuids

Date: 2020-02-10

## Status

Accepted

Supercedes [2. ulids](0002-ulids.md)

## Context

Meadow's predecessor, DONUT, uses straight UUIDs (not ULIDs) as primary identifiers.
Since DONUT's data will be migrated to Meadow, maintaining backward compatibility is
more important than the improved aesthetics or lexical sorting of ULIDs.

## Decision

Remove ULID identifiers in favor of UUIDs.

## Consequences

Since ULIDs are stored in the database as binary UUIDs, this change should have no
effect on existing code or even test data.
