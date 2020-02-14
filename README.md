# Meadow

[![CircleCI](https://circleci.com/gh/nulib/meadow.svg?style=svg)](https://circleci.com/gh/nulib/meadow)
[![Coverage Status](https://coveralls.io/repos/github/nulib/meadow/badge.svg)](https://coveralls.io/github/nulib/meadow)
[![Dependabot Status](https://api.dependabot.com/badges/status?host=github&repo=nulib/meadow)](https://dependabot.com)

## Prerequisites

- Install Erlang and Elixir
  - asdf is a good tool to use for that: [https://asdf-vm.com/](https://asdf-vm.com/)
- Install Node (you can use `nvm` or `asdf` to install node)

  - `brew install nvm`

## Initial setup:

- Make sure you've done the [Local Authentication Setup](https://github.com/nulib/donut/wiki/Authentication-setup-for-dev-environment)
- Install yarn if it's not already present: `brew install npm`, `npm -g install yarn`, or `asdf install yarn [VERSION]`
- From the `meadow` project root, install Elixir dependencies with `mix deps.get`
- Run [devstack](https://github.com/nulib/devstack) environment: `devstack up meadow`
  - The [Kibana](https://www.elastic.co/kibana) utility is not part of the stack by default
  - If you need Kibana, you can start it with the stack by running `devstack up meadow kibana`, or separately using `devstack up -d kibana`
- Create Sequins pipeline, S3 buckets, and database with `mix meadow.setup`
- Setup/seed the LDAP (see below for instructions)
- From the `assets` folder, install Node.js dependencies with `cd assets && yarn install`
- Back in the `meadow` project folder, start the Phoenix endpoint with `mix phx.server` or `iex -S mix phx.server` if you want to an interactive shell.

Now you can visit [`devbox.library.northwestern.edu`](http://devbox.library.northwestern.edu) from your browser.

## Running the application

Start the Phoenix with `mix phx.server` or `iex -S mix phx.server` if you want to an interactive shell.

## Stopping the application

You can stop the Phoneix server with `Ctrl + C` twice

You can stop devstack by running `devstack down`. You local data (from the database, ldap, etc) will persist after devstack shuts down.

If you need to clear your data and reset the entire development environment, run `devstack down -v`

After initial setup, you don't need to run `mix meadow.setup` and `mix meadow.ldap.setup [seed_file ...]` again unless you've run `devstack down -v`.

Read more about [Devstack](https://github.com/nulib/devstack) commands here.

### Dependencies

You may need to run `mix deps.get` again if new dependencies have been added

You may need to run `cd assets && yarn install` if new `node` packages have been added

### Database

If you need to reset the database you can run `mix ecto.reset` which will drop + create + migrate the database

If you just want to run the migrations but leave the data intact, you can just do `mix ecto.migrate`

If you would like to use pgAdmin to view the database and tables, run `devstack up pgadmin` and view it in the browser at: [`http://localhost:5051/`](http://localhost:5051/)

### Seeding the LDAP server

The task `mix meadow.ldap.setup [seed_file ...]` will seed the LDAP database using one or more LDIF files. `mix meadow.ldap.teardown [seed_file ...]` will remove any entries referenced in the seed files.

- Seed files containing a reasonable sample of users and groups for development are available from the NUL dev team.
- A seed file for testing is included in the project and is loaded automatically as part of the `mix test` task.

### Run the test suite

- Start test devstack: `devstack -t up meadow`
- run `mix test`

### Amazon s3/Minio

`http://localhost:9001/minio/` is where you can see your local "s3" buckets.

**Login**: minio
**Password**: minio123

### GraphQL API

You can visit the GraphiQL interface at: [`http://devbox.library.northwestern.edu/api/graphiql`](http://devbox.library.northwestern.edu/api/graphiql)
