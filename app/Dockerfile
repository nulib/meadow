ARG BUILD_IMAGE

# Install elixir & npm dependencies
FROM ${BUILD_IMAGE} AS build
LABEL edu.northwestern.library.app=meadow \
      edu.northwestern.library.cache=true \
      edu.northwestern.library.stage=deps
ARG NODE_VERSION=22
ENV NPM_VERSION=11.6.0
ENV ARCH=x64
RUN apt update -qq
RUN apt install -y ca-certificates curl git gnupg
RUN mkdir -p /etc/apt/keyrings
RUN curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
RUN echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_${NODE_VERSION}.x nodistro main" | tee /etc/apt/sources.list.d/nodesource.list
RUN apt update -qq
RUN apt install -y nodejs
RUN npm install -g npm@$NPM_VERSION
RUN  mix local.hex --force \
  && mix local.rebar --force
ENV MIX_ENV=prod
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
      (cd $(dirname ${flag}) && npm ci); \
    done
WORKDIR /app
ARG HONEYBADGER_API_KEY=
ARG HONEYBADGER_API_KEY_FRONTEND=
ARG HONEYBADGER_ENVIRONMENT=
ARG HONEYBADGER_REVISION=
ARG MEADOW_TENANT=
ARG MEADOW_VERSION=
ARG RELEASE_NAME=
ENV RELEASE_NAME=${RELEASE_NAME}
RUN mix release --overwrite

# Create runtime image
FROM ${BUILD_IMAGE}
LABEL edu.northwestern.library.app=meadow \
      edu.northwestern.library.stage=runtime
ARG NODE_VERSION=22
RUN apt update -qq && apt install -y ca-certificates curl git gnupg jq libssl-dev libncurses5-dev \
  && mkdir -p /etc/apt/keyrings \
  && curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg \
  && echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_${NODE_VERSION}.x nodistro main" | tee /etc/apt/sources.list.d/nodesource.list \
  && apt update -qq \
  && apt install -y nodejs
ARG RELEASE_NAME=
ENV RELEASE_NAME=${RELEASE_NAME}
ENV LANG=C.UTF-8
EXPOSE 4000 4369 9100-9155
COPY --from=build /app/_build/prod/rel/meadow /app
WORKDIR /app
ENTRYPOINT ["./bin/meadow"]
CMD ["start"]
