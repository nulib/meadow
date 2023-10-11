ARG BUILD_IMAGE
ARG RUNTIME_IMAGE

# Install elixir & npm dependencies
FROM ${BUILD_IMAGE} AS build
LABEL edu.northwestern.library.app=meadow \
  edu.northwestern.library.cache=true \
  edu.northwestern.library.stage=deps
ARG HONEYBADGER_API_KEY=
ARG HONEYBADGER_API_KEY_FRONTEND=
ARG HONEYBADGER_ENVIRONMENT=
ARG HONEYBADGER_REVISION=
ARG MEADOW_VERSION=
ENV MIX_ENV=prod
RUN  mix local.hex --force \
  && mix local.rebar --force
ENV NODE_VERSION 18
ENV NPM_VERSION 10.1.0
ENV ARCH x64
RUN apt update -qq \
 && apt install -y ca-certificates curl git gnupg \
 && mkdir -p /etc/apt/keyrings \
 && curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg \
 && echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_${NODE_VERSION}.x nodistro main" | tee /etc/apt/sources.list.d/nodesource.list \
 && apt update -qq \
 && apt install -y nodejs \
 && npm install -g npm@$NPM_VERSION
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
FROM ${RUNTIME_IMAGE}
LABEL edu.northwestern.library.app=meadow \
  edu.northwestern.library.stage=runtime
RUN apt update -qq && apt install -y curl jq libssl-dev libncurses5-dev
ENV LANG=en_US.UTF-8
EXPOSE 4000 4369
COPY --from=build /app/_build/prod/rel/meadow /app
WORKDIR /app
ENTRYPOINT ["./bin/meadow"]
CMD ["start"]
