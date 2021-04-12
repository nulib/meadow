# 18. Preservation Storage Object Naming Scheme

Date: 2019-10-11

## Status

Accepted

Amended by [28. Use Only FileSet Digest for Preservation Object Name](0028-use-only-fileset-digest-for-preservation-object-name.md)

## Context

The application needs a way to store objects in preservation buckets that facilitate upload and retrieval and allows for duplicate file names among FileSets associated with a Work object.

## Decision

Use a combination of the pairtree of a FileSet ULID plus its sha256 checksum as the key for S3 objects in the preservation bucket. So an FileSet with a ULID `01dpxt2xajvkdsbckqrs8ry677`
and sha256 checksum `87d2c7faf7774a8b07c43be06055c67c4bd602b8ec0e9d6b15241967d500d356`will be stored in s3 as
`s3://[preservation-bucket]/01/dp/xt/2x/01dpxt2xajvkdsbckqrs8ry677/87d2c7faf7774a8b07c43be06055c67c4bd602b8ec0e9d6b15241967d500d356`

## Consequences

If we decide to change the naming scheme later we will have to migrate existing objects to the new scheme.
