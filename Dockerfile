FROM elixir:1.9.0 AS build
RUN apt-get update -qq \
 && apt-get install -y curl \
 && curl -sL https://deb.nodesource.com/setup_11.x | bash - \
 && apt-get install -y nodejs \
 && apt-get clean -y \
 && rm -rf /var/lib/apt/lists/* \
 && mix local.hex --force \
 && mix local.rebar --force
ENV MIX_ENV=prod
COPY ./mix.exs /app/mix.exs
COPY ./mix.lock /app/mix.lock
WORKDIR /app
RUN mix do deps.get --only prod, deps.compile 
COPY . /app
RUN cd assets \
 && npm install \
 && node_modules/.bin/webpack \
 && cd ..
RUN mix phx.digest \
 && mix release --overwrite

FROM debian:stretch AS run
RUN apt-get update -qq \
 && apt-get install -y openssl tzdata locales \
 && apt-get clean -y \
 && rm -rf /var/lib/apt/lists/*
RUN dpkg-reconfigure -f noninteractive tzdata && \
    sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && \
    echo 'LANG="en_US.UTF-8"'>/etc/default/locale && \
    dpkg-reconfigure --frontend=noninteractive locales && \
    update-locale LANG=en_US.UTF-8
ENV LANG=en_US.UTF-8
EXPOSE 4000
COPY --from=build /app/_build/prod/rel/meadow /app
WORKDIR /app
ENTRYPOINT ["/app/bin/meadow"]
CMD ["start"]