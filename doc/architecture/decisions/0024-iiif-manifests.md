# 24. IIIF Manifests

Date: 2020-03-06

## Status

Accepted

Supercedes [22. IIIF Manifests](0022-iiif-manifests.md)

## Context

Since January, when we developed the strategy for IIIF Manifests in ADR 22, we have decided that Donut/Glaze will be decomissioned at or before the time that Meadow/Fen are live in production.

In light of this, we decided to go with a simpler approach to routing requests for Meadow vs. Donut manifests in the staging environment.

## Decision

We will not build the lambda that checks for the host application, instead we will use the API Gateway to route all requests for public IIIF manifests to the pyramids bucket's public directory on S3.

## Consequences

This will slightly impact performance of manifests on Glaze (staging only), since Donut manifests will not be rechecked and cached on every request. However, the trade-off is that for Meadow, the setup was greatly simplified, and we didn't expend developer hours on a temporary workaround.
