# Meadow

[![CircleCI](https://circleci.com/gh/nulib/meadow.svg?style=svg)](https://circleci.com/gh/nulib/meadow)
[![Coverage Status](https://coveralls.io/repos/github/nulib/meadow/badge.svg)](https://coveralls.io/github/nulib/meadow)
[![Dependabot Status](https://api.dependabot.com/badges/status?host=github&repo=nulib/meadow)](https://dependabot.com)

## Initial setup:

- Make sure you've done the [Local Authentication Setup](https://github.com/nulib/donut/wiki/Authentication-setup-for-dev-environment)
- Install yarn if it's not already present: `npm -g install yarn`
- Install dependencies with `mix deps.get`
- Run [devstack](https://github.com/nulib/devstack) environment: `devstack up meadow`
- Create Sequins pipeline, S3 buckets, and database with `mix meadow.setup`
- Install Node.js dependencies with `cd assets && yarn install`
- Start Phoenix endpoint with `mix phx.server`

Now you can visit [`devbox.library.northwestern.edu`](http://devbox.library.northwestern.edu) from your browser.

## Running the application

You can simply run the application with `mix phx.server`

After initial setup, you don't need to run `mix meadow.setup` again, but if there are database changes you'll need to run `mix ecto.migrate` before starting the Phoenix server. Or, you can run `mix ecto.reset` which will drop and recreate the database and run the migrations. If you need to reset the entire development environment, run `devstack down -v` and go back to the last three steps of Initial Setup.

### Dependencies

You may need to run `mix deps.get` or `mix deps.compile` again if new dependencies have been added

You may need to run `cd assets && yarn install` if new `node` packages have been added

### Database

If you need to reset the database you can run `mix ecto.reset` which will drop + create + migrate the database

If you just want to run the migrations but leave the data intact, you can just do `mix ecto.migrate`

If you would like to use pgAdmin to view the database and tables, run `devstack up pgadmin` and view it in the browser at: [`http://localhost:5051/`](http://localhost:5051/)

### Run the test suite

- Start test devstack: `devstack -t up meadow`
- run `mix test`

### Amazon s3/Minio

`http://localhost:9001/minio/` is where you can see your local "s3" buckets.

**Login**: minio
**Password**: minio123

### GraphQL API

You can visit the GraphiQL interface at: [`http://devbox.library.northwestern.edu/api/graphiql`](http://devbox.library.northwestern.edu/api/graphiql)
