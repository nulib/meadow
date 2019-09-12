# 14. active-directory-groups

Date: 2019-09-03

## Status

Accepted

## Context

Meadow needs a mechanism to track user privileges.

## Decision

Use existing Library Active Directory group membership to map users to
sets of privileges and access controls.

## Consequences

We will still need to create a model and a UI to relate different AD/LDAP
groups to app-specific resource/route privileges, but we won't have to
develop a group creation/membership/management interface or manage the
privileges required to manipulate it.
