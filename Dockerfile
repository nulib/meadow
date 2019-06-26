FROM elixir:1.9.0 AS build
RUN  mix local.hex --force \
  && mix local.rebar --force
ENV MIX_ENV=prod
COPY . /app
WORKDIR /app
RUN mix deps.get --only prod \
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