# 28. Use Only FileSet Digest for Preservation Object Name

Date: 2021-04-12

## Status

Accepted

Amends [18. Preservation Storage Object Naming Scheme](0018-preservation-storage-object-naming-scheme.md)

## Context

The earlier [18. Preservation Storage Object Naming Scheme](Preservation Storage Object Naming Scheme) decision called for a combination of ULID (for the pairtree) and sha256 (for the leaf name) as the key for the preservation object. In practice, we have used a pairtree/leaf combination built entirely of the sha256 without regard to the object's identifier.

## Decision

Use the pairtree of a FileSet's sha256 checksum as the key for S3 objects in the preservation bucket. So a FileSet with the sha256 checksum `87d2c7faf7774a8b07c43be06055c67c4bd602b8ec0e9d6b15241967d500d356`will be stored in s3 as
`s3://[preservation-bucket]/87/d2/c7/fa/01dpxt2xajvkdsbckqrs8ry677/87d2c7faf7774a8b07c43be06055c67c4bd602b8ec0e9d6b15241967d500d356`

## Consequences

None for the time being – this decision merely documents how Meadow works in practice.
