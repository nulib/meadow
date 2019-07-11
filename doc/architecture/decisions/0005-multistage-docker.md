# 5. multistage-docker

Date: 2019-06-28

## Status

Accepted

## Context

We need an efficient, automated build process that creates an Elixir
release within a compact Docker container.

## Decision

We use a [multi-stage Dockerfile](https://docs.docker.com/develop/develop-images/multistage-build/) to install Elixir dependencies,
build JavaScript assets, and create the Elixir release in separate
containers, then copy all of the artifacts into a bare-bones Alpine
runtime image.

## Consequences

* Builds are faster thanks to Docker [layer caching](https://docs.docker.com/develop/develop-images/dockerfile_best-practices/)
* Runtime image is tiny (~70MB as of this decision)
* Developers don't have to worry about pre-building assets before checking in
  code
