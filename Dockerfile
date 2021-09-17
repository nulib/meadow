# Install elixir & npm dependencies
FROM nulib/elixir-phoenix-base:1.12.1 AS deps
LABEL edu.northwestern.library.app=meadow \
  edu.northwestern.library.cache=true \
  edu.northwestern.library.stage=deps
ENV MIX_ENV=prod
COPY ./mix.exs /app/mix.exs
COPY ./mix.lock /app/mix.lock
COPY ./config /app/config
WORKDIR /app
RUN mix deps.get --only prod \
    && mix deps.compile
COPY ./assets/package.json /app/assets/package.json
COPY ./assets/yarn.lock /app/assets/yarn.lock
WORKDIR /app/assets
RUN yarn install
COPY ./priv/nodejs /app/priv/nodejs
WORKDIR /app/priv/nodejs
RUN for flag in $(find . -name .docker-yarn); do \
      yarn install --cwd $(dirname ${flag}); \
    done

# Create elixir release
FROM nulib/elixir-phoenix-base:1.12.1 AS release
ARG HONEYBADGER_API_KEY=
ARG HONEYBADGER_API_KEY_FRONTEND=
ARG HONEYBADGER_ENVIRONMENT=
ARG HONEYBADGER_REVISION=
ARG MEADOW_VERSION=
ENV MIX_ENV=prod
COPY . /app
COPY --from=deps /app/_build /app/_build
COPY --from=deps /app/deps /app/deps
COPY --from=deps /app/assets/node_modules /app/assets/node_modules
COPY --from=deps /app/priv/nodejs /app/priv/nodejs
WORKDIR /app
RUN mix release --overwrite

# Create runtime image
FROM node:14-alpine
LABEL edu.northwestern.library.app=meadow \
  edu.northwestern.library.stage=runtime
RUN apk update && apk --no-cache --update add curl jq ncurses-libs openssl-dev
ENV LANG=en_US.UTF-8
EXPOSE 4000 4369 24601
COPY --from=release /app/_build/prod/rel/meadow /app
WORKDIR /app
ENTRYPOINT ["./bin/meadow"]
CMD ["start"]
