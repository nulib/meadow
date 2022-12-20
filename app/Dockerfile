# Install elixir & npm dependencies
FROM nulib/elixir-phoenix-base:1.12.1 AS deps
LABEL edu.northwestern.library.app=meadow \
  edu.northwestern.library.cache=true \
  edu.northwestern.library.stage=deps
ENV MIX_ENV=prod
COPY ./mix.exs /app/mix.exs
COPY ./mix.lock /app/mix.lock
COPY ./config/config.exs ./config/prod.exs ./config/pipeline.exs /app/config/
COPY ./lib/env.ex /app/lib/
WORKDIR /app
RUN mix deps.get --only prod \
    && mix deps.compile
COPY ./assets/package.json /app/assets/package.json
COPY ./assets/package-lock.json /app/assets/package-lock.json
WORKDIR /app/assets
RUN npm install
COPY ./priv/nodejs /app/priv/nodejs
WORKDIR /app/priv/nodejs
RUN for flag in $(find . -name .docker-npm); do \
      cd $(dirname ${flag}); \
      npm install; \
      cd -; \
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
RUN apk update && apk --no-cache --update add curl jq libcrypto1.1 ncurses-libs openssl-dev
ENV LANG=en_US.UTF-8
EXPOSE 4000 4369 24601
COPY --from=release /app/_build/prod/rel/meadow /app
WORKDIR /app
ENTRYPOINT ["./bin/meadow"]
CMD ["start"]
