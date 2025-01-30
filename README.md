# Meadow

[![Build](https://github.com/nulib/meadow/actions/workflows/test.yml/badge.svg)](https://github.com/nulib/meadow/actions/workflows/test.yml)
[![Coverage Status](https://coveralls.io/repos/github/nulib/meadow/badge.svg)](https://coveralls.io/github/nulib/meadow)
<!-- [![Dependabot Status](https://api.dependabot.com/badges/status?host=github&repo=nulib/meadow)](https://dependabot.com) -->

## Prerequisites

- [NUL's AWS Cloud Developer Environment](https://github.com/nulib/aws-developer-environment) setup

## Initial startup:

- From the `meadow` project root, `cd app`.
- Install Elixir dependencies with `mix deps.get`
- Run `mix meadow.setup`. This creates the Sequins pipeline, S3 buckets, and database.
- Install Node.js dependencies with `mix assets.install`
  - `assets.install` looks for all `package-lock.json` files project-wide and runs `npm install` in each directory found, so you don't need to run `npm install` in individual directories.
- run `sg open all 3001`
- Start the Phoenix server with `mix phx.server` (or `iex -S mix phx.server` if you want to an interactive shell).

Now you can visit [`https://[YOURENV].dev.rdc.library.northwestern.edu:3001/`](https://[YOURENV].dev.rdc.library.northwestern.edu:3001/) from your browser.

## Stopping the application

You can stop the Phoenix server with `Ctrl + C` twice

## Clearing and resetting data

If you need to clear your data and reset the entire development environment, from `meadow/app` run:

```
mix ecto.reset
mix meadow.search.clear
mix meadow.pipeline.purge
clean-s3 dev -y

...then
mix deps.get
mix meadow.setup
mix phx.server
```

### Dependencies

You may need to run `mix deps.get` again if new dependencies have been added

You may need to run `mix assets.install` if new `node` packages have been added

### Database

If you need to reset the database you can run `mix ecto.reset` which will drop + create + migrate the database

If you just want to run the migrations but leave the data intact, you can just do `mix ecto.migrate`

If you would like to interact directly with the database

### Run the Elixir test suite

#### Start Test Services

In one terminal:
```
cd infrastructure/localstack
docker compose up
```

#### Provision Test Environment

Watch the logs until the services seem to stabilize. Then, in another terminal:
```
cd infrastructure/localstack
terraform init
terraform apply -auto-approve \
  -var-file test.tfvars \
  -var localstack_endpoint=https://localhost.localstack.cloud:4566
```

You will probably see `Warning: AWS account ID not found for provider`, but this can be safely ignored.

#### Run Tests

```
cd app
mix test [test args...]
```

**Note:** `mix test` can be run repeatedly without re-provisioning as long as the Docker services are running. If you stop the services, you will need to run Terraform again.

### GraphQL API

You can visit the GraphiQL interface at: [`https://[YOURENV].dev.rdc.library.northwestern.edu:3001/api/graphiql`](https:/[YOURENV].dev.rdc.library.northwestern.edu:3001/api/graphiql)

### Livebook Integration

To start meadow with superuser Livebook integration, run: `MEADOW_ROOT/bin/meadow-livebook [iex arguments]`

For example, from Meadow's root directory: `./bin/meadow-livebook phx.server`

### Opensearch Dashboard

- To start: `es-proxy start`
- To stop: `es-proxy stop`
- See the console output for the url to the dashboard

### Digital Collections API

In order to see data and thumbnails from your current environment, you'll need to run the DC API alongside Meadow. Follow the instructions for [Running the API locally](https://github.com/nulib/dc-api-v2#running-the-api-locally) and [Running the API locally via our AWS dev domain](Running the API locally via our AWS dev domain) to get it running.

### Reindexing data

To force an Elasticsearch re-index, and not wait for the 2-minute cycle to kick in when updating a Meadow item:

Run the interactive shell in a terminal tab

```
iex -S mix
```

And force a re-index:

```
Meadow.Data.Indexer.reindex_all()
```

### Doing development on the Meadow Pipeline lambdas

In the AWS developer environment, the lambdas associated with the pipeline are shared amongst developers. In order to do development and see whether it's working you can override the configuration to use your local files instead of the deployed lambdas. Example below (you don't have to override them all. Just the ones you need).

Edit `config/dev.local.exs` to get the lambdas to use the local copy through the port:`

```elixir
  config :meadow, :lambda,
    digester: {:local, {Path.expand("../lambdas/digester/index.js"), "handler"}},
    exif: {:local, {Path.expand("../lambdas/exif/index.js"), "handler"}},
    frame_extractor: {:local, {Path.expand("../lambdas/frame-extractor/index.js"), "handler"}},
    mediainfo: {:local, {Path.expand("../lambdas/mediainfo/index.js"), "handler"}},
    mime_type: {:local, {Path.expand("../lambdas/mime-type/index.js"), "handler"}},
    tiff: {:local, {Path.expand("../lambdas/pyramid-tiff/index.js"), "handler"}}
```

### TypeScript/GraphQL Types

Meadow now supports TypeScript and GraphQL types in the React app. To generate types, run the following commands:

```bash
# Generate a local JSON version of GraphQL schema
mix graphql.schema.export -o priv/graphql/schema.json

# Generate TypeScript types for the UI
cd assets
npm run generate-types
```

Types will be generated in `meadow/app/assets/js/__generated__`. You can import them into React components like so:

```tsx
import type { FileSet, Work as WorkType } from "@js/__generated__/graphql";

const SomeComponent = ({ work }: { work: WorkType }) => {
  // ...
};
```

### Terraform

Meadow's Terraform code is stored in this repo. To run Terraform commands, you'll need to do the [configuration setup](https://github.com/nulib/repodev_planning_and_docs/blob/a36472895ae5c851f4f36b6f598dc5f666cea672/docs/2._Developer_Guides/Meadow/Terraform-Setup-on-Meadow.md)

### UI Customization

Meadow runs in Development, Staging and Production environments. To help distinguish environments (and avoid potential errors), Staging and Development environments support alternate, background colors.

#### Production

- A wrapper CSS class of `is-production-environment` wraps the `main` HTML element (in case anyone wants to target a selector for any reason).

#### Staging

- Supports a toggle background color switch in the site header
- Customize your own dev background color by updating the hex value for `localStorage` property `devBg`
- A wrapper CSS class of `is-staging-environment` wraps the `main` HTML element.

#### Development

- Supports a toggle background color switch in the site header
- Customize your own dev background color by updating the hex value for `localStorage` property `devBg`
- A wrapper CSS class of `is-development-environment` wraps the `main` HTML element.
