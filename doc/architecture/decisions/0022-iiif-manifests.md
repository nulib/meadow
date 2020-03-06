# 22. IIIF Manifests

Date: 2020-01-27

## Status

Superceded by [24. IIIF Manifests](0024-iiif-manifests.md)

## Context

Currently requests for public manifests are routed through Donut in order to be re-cached in S3 if needed. We need to plan a strategy to handle IIIF manifest requests for manifests which were written by Meadow and should not be routed through Donut.

## Decision

- Manifests will be written for all works (public/private/restricted) on create/update.
- IIIF Manifests will be written on to the `public` directory of the existing stack-\*-pyramids bucket, and will live alongside existing Donut manifests.
- Requests for public manifests moving forward will route from the API gateway to a new lambda which will check Elasticsearch for the host application. Then it will either route directly to the S3 Pyramids `/public` folder (Meadow) or to Donut. (This is temporary, until Donut content is migrated.)
- Meadow will use these manifests internally

## Consequences

This strategy will allow us to preserve existing IIIF Manifest urls.
