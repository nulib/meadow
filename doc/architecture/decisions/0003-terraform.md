# 3. terraform

Date: 2019-06-27

## Status

Accepted

## Context

Previously we've kept Terraform code in a separate Github repository (nulterra) and this has had the effect of making changes more cumbersome. 

## Decision

We've decided to keep Meadow Terraform code inside the Meadow repository in a root directory called `terraform`.

## Consequences

It will be easier to maintain deployment code alongside the app. Developers will have to run `terraform apply` from within the `terraform` directory of the Meadow app on their local machines. 
