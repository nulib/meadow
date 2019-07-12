# Meadow

[![CircleCI](https://circleci.com/gh/nulib/meadow.svg?style=svg)](https://circleci.com/gh/nulib/meadow)
[![Coverage Status](https://coveralls.io/repos/github/nulib/meadow/badge.svg)](https://coveralls.io/github/nulib/meadow)

Initial Setup:

- Install yarn if it's not already present: `npm -g install yarn`
- Run [devstack](https://github.com/nulib/devstack) environment: `devstack up meadow`
- Install dependencies with `mix deps.get`
- Create and migrate your database with `mix ecto.setup`
- Install Node.js dependencies with `cd assets && yarn install`
- Start Phoenix endpoint with `mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

You can visit the SwaggerUI at: [`http://localhost:4000/swaggerui`](http://localhost:4000/swaggerui)

To regenerate the OpenAPI spec run
`mix meadow.open_api_spec spec.json`

After initial setup, you don't need to run `mix ecto.setup` again

- You can simply run the application with `mix phx.server`
- You may need to run `mix deps.get` or `mix deps.compile` again if new dependencies have been added
- You map need to run `cd assets && yarn install` if new node packages have been added
- If you need to reset the database you can run `mix ecto.reset` which will drop + create + migrate the database
- If you just want to run the migrations but leave the data intact, you can just do `mix ecto.migrate`
