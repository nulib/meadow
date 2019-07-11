# 9. Tailwind CSS framework

Date: 2019-07-11

## Status

Accepted

## Context

We have used opinionated CSS frameworks such as Twitter Bootstrap in the past, and have found that we spend too much effort and time working around those opinions. Tailwind CSS offers an alternative approach that allows us to iterate quickly with minimal interference from the framework by allowing us to add layout and styles directly in our HTML rather than CSS.

## Decision

Use the Tailwind CSS framework for design and layout.

## Consequences

Tailwind will allow us to build out the design, components and layout of the application without getting in the way. The major risk in using this framework is that it is utility-first rather than semantic, so your HTML class attributes can appear convoluted.
