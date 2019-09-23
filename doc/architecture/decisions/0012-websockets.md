# 12. websockets

Date: 2019-07-26

## Status

Accepted

## Context

We need a way to provide live updates to the front-end for ingest sheet validation,
ingest status, etc.

## Decision

We will use the [WebSocket API](https://www.w3.org/TR/websockets/) via [Phoenix Channels](https://hexdocs.pm/phoenix/channels.html) to enable real-time communication between the client and server.

## Consequences

In order for websockets to work correctly, the Phoenix application cannot be behind
an HTTP/S load balancer. Instead, we need to use a TCP/TLS load balancer.
