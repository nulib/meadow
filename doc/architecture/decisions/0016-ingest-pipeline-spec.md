# 16. ingest-pipeline-spec

Date: 2019-09-17

## Status

Accepted

## Context

Per [issue #1104](https://github.com/nulib/next-generation-repository/issues/1104): Developers need a (basic/nothing fancy) general, conceptual/overall understanding/plan of what form the ingest pipeline will take so that different pieces may effectively be worked on by different people.

## Decision

We developed a specification for a flexible, message-driven [Ingest Pipeline](../specs/ingest_pipeline.md).

## Consequences

Using this spec, we will be able to break down the ingest process into a series of atomic actions, with consistent progress tracking and error reporting. Further refinements may be required, and will be handled by subsequent ADRs.
