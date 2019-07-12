# Install elixir dependencies
FROM elixir:1.9.0-alpine AS deps
LABEL edu.northwestern.library.app=meadow \
  edu.northwestern.library.stage=deps
RUN mix local.hex --force \
  && mix local.rebar --force
ENV MIX_ENV=prod
COPY ./mix.exs /app/mix.exs
COPY ./mix.lock /app/mix.lock
WORKDIR /app
RUN mix do deps.get --only prod, deps.compile 

# Build static assets using nodejs & webpacker
FROM node:11-alpine AS assets
LABEL edu.northwestern.library.app=meadow \
  edu.northwestern.library.stage=assets
COPY ./assets /app/assets
COPY --from=deps /app/deps/phoenix /app/deps/phoenix
COPY --from=deps /app/deps/phoenix_html /app/deps/phoenix_html
WORKDIR /app/assets
RUN npm -g install yarn \
  && yarn install \
  && yarn deploy

# Create elixir release
FROM elixir:1.9.0-alpine AS release
RUN mix local.hex --force \
  && mix local.rebar --force
ENV MIX_ENV=prod
COPY . /app
COPY --from=deps /app/_build /app/_build
COPY --from=deps /app/deps /app/deps
COPY --from=assets /app/priv/static /app/priv/static
WORKDIR /app
RUN mix phx.digest \
  && mix release --overwrite

# Create runtime image
FROM alpine:3.9
LABEL edu.northwestern.library.app=meadow \
  edu.northwestern.library.stage=runtime
RUN apk update && apk --no-cache --update add ncurses-libs openssl-dev
ENV LANG=en_US.UTF-8
EXPOSE 4000
COPY --from=release /app/_build/prod/rel/meadow /app
WORKDIR /app
ENTRYPOINT ["./bin/meadow"]
CMD ["start"]