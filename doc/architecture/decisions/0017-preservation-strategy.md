# 17. Preservation Strategy

Date: 2019-10-11

## Status

Accepted

## Context

Having a "preservation first" mindset has been decided upoan as a stated goal for Meadow. Generally, this means that digital preservation
policies, processes and deliverables should be planned and implemented in tandem with development of the applications features, processeses and infrastructure.

## Decision

The digital preservation lifecycle for a Work and its FileSets begin as soon as an Ingest Sheet is "approved". Actions in the ingest pipeline are used to
add digital preservation "artifacts" to Work and FileSet metadata (such as checksum and timestamps) and move objects to preservation storage buckets in S3. Additionally, the
success and failure outcomes of these actions are added as AuditEntries that can be used verification, future audits and problem resolution.

## Consequences

The riskiest aspect of this strategy is that the application is rapidly evolving and we may have to alter aspects of our digital preservation strategy
as we learn more about our chosen infrastructure's offerings and limitations over time.
