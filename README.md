# Meadow

[![CircleCI](https://circleci.com/gh/nulib/meadow.svg?style=svg)](https://circleci.com/gh/nulib/meadow)
[![Coverage Status](https://coveralls.io/repos/github/nulib/meadow/badge.svg)](https://coveralls.io/github/nulib/meadow)
[![Dependabot Status](https://api.dependabot.com/badges/status?host=github&repo=nulib/meadow)](https://dependabot.com)

## Prerequisites

- Install Erlang and Elixir
  - asdf is a good tool to use for that: [https://asdf-vm.com/](https://asdf-vm.com/)
- Install Node (you can use `nvm` (`brew install nvm`) or `asdf` to install node)
- Install libffi `brew install libffi`

## Initial setup:

- Make sure you've done the [Local Authentication Setup](https://github.com/nulib/donut/wiki/Authentication-setup-for-dev-environment)
- Install yarn if it's not already present: `npm -g install yarn`, or `asdf install yarn [VERSION]`
- From the `meadow` project root, install Elixir dependencies with `mix deps.get`
- Run `devstack up meadow` to start the [devstack](https://github.com/nulib/devstack) environment:
  - The [Kibana](https://www.elastic.co/kibana) utility is not part of the stack by default
  - If you need Kibana, you can start it with the stack by running `devstack up meadow kibana`, or separately using `devstack up -d kibana`
- Run `mix meadow.setup`. This creates the Sequins pipeline, S3 buckets, and database.
- Setup/seed the LDAP ([see below](###seeding-the-ldap-server) for instructions)
  - You can run both the general setup and the LDAP setup at the same time with `mix do meadow.setup, meadow.ldap.setup /path/to/seed/file/filename.ldif`
- Install Node.js dependencies with `mix assets.install`
  - `assets.install` looks for all `yarn.lock` files project-wide and runs `yarn install` in each directory found, so you don't need to run `yarn install` in individual directories.
- `cd` back to the `meadow` project folder and start the Phoenix endpoint with `mix phx.server` or `iex -S mix phx.server` if you want to an interactive shell.
- Set up Meadow for SSL and Agentless SSO:
  - Copy both [devbox certificate files](https://github.com/nulib/miscellany/tree/master/devbox_cert) to `priv/cert/`
  - Copy the [Meadow SSL config](https://github.com/nulib/miscellany/blob/master/meadow/config/dev.local.exs) to `config/`

Now you can visit [`devbox.library.northwestern.edu`](https://devbox.library.northwestern.edu:3001) from your browser.

## Running the application

Start the Phoenix with `mix phx.server` or `iex -S mix phx.server` if you want to an interactive shell.

## Stopping the application

You can stop the Phoneix server with `Ctrl + C` twice

You can stop devstack by running `devstack down`. You local data (from the database, ldap, etc) will persist after devstack shuts down.

If you need to clear your data and reset the entire development environment, run `devstack down -v`

After initial setup, you don't need to run `mix meadow.setup` and `mix meadow.ldap.setup [seed_file ...]` again unless you've run `devstack down -v`.

If changes have been made to devstack itself, you may need to run `devstack pull` and/or `devstack update`

Read more about [Devstack](https://github.com/nulib/devstack) commands here.

### Dependencies

You may need to run `mix deps.get` again if new dependencies have been added

You may need to run `mix assets.install` if new `node` packages have been added

### Database

If you need to reset the database you can run `mix ecto.reset` which will drop + create + migrate the database

If you just want to run the migrations but leave the data intact, you can just do `mix ecto.migrate`

If you would like to interact directly with the database

- you can use pgAdmin to view the database and tables, run `devstack up pgadmin` and view it in the browser at: [`http://localhost:5051/`](http://localhost:5051/)
- Alternatively, you can dowload a tool like [PSequel](http://www.psequel.com/)

### Seeding the LDAP server

The task `mix meadow.ldap.setup [seed_file ...]` will seed the LDAP database using one or more LDIF files. `mix meadow.ldap.teardown [seed_file ...]` will remove any entries referenced in the seed files.

- Seed files containing a reasonable sample of users and groups for development are available from the NUL dev team.
- A seed file for testing is included in the project and is loaded automatically as part of the `mix test` task.

### Run the Elixir test suite

- Start test devstack: `devstack -t up meadow`
- run `mix test`

### Amazon s3/Minio

See your local "s3" buckets.

- Dev: `http://localhost:9001/minio/`
- Test: `http://localhost:9002/minio/`

**Login**: minio
**Password**: minio123

### GraphQL API

You can visit the GraphiQL interface at: [`http://devbox.library.northwestern.edu/api/graphiql`](http://devbox.library.northwestern.edu/api/graphiql)

### IIIF Server

In dev mode, the IIIF Server is available at: `http://localhost:8183/iiif/2`

### Elasticsearch + Kibana

- In dev mode, Elasticsearch is available at: `http://localhost:9201`
- In dev mode, Kibana (if started) is available at: `http://localhost:5602/`

### LDAP

The development LDAP is available at `localhost` port `390`

### Terraform

Meadow's Terraform code is stored in this repo. To run Terraform commands, you'll need to do the [configuration setup](https://github.com/nulib/repodev_planning_and_docs/blob/a36472895ae5c851f4f36b6f598dc5f666cea672/docs/2._Developer_Guides/Meadow/Terraform-Setup-on-Meadow.md)
