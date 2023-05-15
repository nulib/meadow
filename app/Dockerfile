# Install elixir & npm dependencies
FROM hexpm/elixir:1.15.4-erlang-26.0.2-alpine-3.18.2 AS build
LABEL edu.northwestern.library.app=meadow \
  edu.northwestern.library.cache=true \
  edu.northwestern.library.stage=deps
ARG HONEYBADGER_API_KEY=
ARG HONEYBADGER_API_KEY_FRONTEND=
ARG HONEYBADGER_ENVIRONMENT=
ARG HONEYBADGER_REVISION=
ARG MEADOW_VERSION=
ENV MIX_ENV=prod
RUN  apk add --update --repository https://dl-3.alpinelinux.org/alpine/edge/testing/ curl git libstdc++ \
  && mix local.hex --force \
  && mix local.rebar --force
ENV NODE_VERSION 18.18.0
ENV NPM_VERSION 10.1.0
ENV ARCH x64
RUN curl -fsSLO --compressed "https://unofficial-builds.nodejs.org/download/release/v$NODE_VERSION/node-v$NODE_VERSION-linux-$ARCH-musl.tar.xz"; \
  tar -xJf "node-v$NODE_VERSION-linux-$ARCH-musl.tar.xz" -C /usr/local --strip-components=1 --no-same-owner \
  && ln -s /usr/local/bin/node /usr/local/bin/nodejs && \
  npm install -g npm@$NPM_VERSION; \
  rm -f "node-v$NODE_VERSION-linux-$ARCH-musl.tar.xz";
COPY . /app
WORKDIR /app
RUN mix deps.get --only prod \
    && mix deps.compile
COPY ./assets/package.json /app/assets/package.json
COPY ./assets/package-lock.json /app/assets/package-lock.json
WORKDIR /app/assets
RUN npm ci --force
COPY ./priv/nodejs /app/priv/nodejs
WORKDIR /app/priv/nodejs
RUN for flag in $(find . -name .docker-npm); do \
      cd $(dirname ${flag}); \
      npm ci; \
      cd -; \
    done
WORKDIR /app
RUN mix release --overwrite

# Create runtime image
FROM node:18-alpine
LABEL edu.northwestern.library.app=meadow \
  edu.northwestern.library.stage=runtime
RUN apk update && apk --no-cache --update add curl jq libcrypto3 ncurses-libs openssl-dev
ENV LANG=en_US.UTF-8
EXPOSE 4000 4369 24601
COPY --from=build /app/_build/prod/rel/meadow /app
WORKDIR /app
ENTRYPOINT ["./bin/meadow"]
CMD ["start"]
