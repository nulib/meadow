defmodule Meadow.Runtime.Dev do
  @moduledoc false

  import Config
  import Meadow.Runtime

  def configure! do
    config :meadow, Meadow.Repo,
      show_sensitive_data_on_connection_error: true,
      timeout: 60_000,
      connect_timeout: 60_000,
      handshake_timeout: 60_000,
      pool_size: 50

    config :meadow, index_interval: 30_000

    config :meadow, Meadow.Scheduler,
      overlap: false,
      timezone: "America/Chicago",
      jobs: [
        # Runs every 10 minutes:
        {"*/10 * * * *", {Meadow.Data.PreservationChecks, :start_job, []}}
      ]

    # Do not include metadata nor timestamps in development logs
    config :logger, :console,
      format: "$metadata[$level] $message\n",
      metadata: [:module, :id]

    # Set a higher stacktrace during development. Avoid configuring such
    # in production as building large stacktraces may be expensive.
    config :phoenix, :stacktrace_depth, 20

    # Initialize plugs at runtime for faster development compilation
    config :phoenix, :plug_init_mode, :runtime

    config :meadow, :sitemaps,
      gzip: false,
      store: Sitemapper.FileStore,
      sitemap_url: "https://devbox.library.northwestern.edu:3333/",
      store_config: [path: "priv/static"]

    config(:meadow, MeadowWeb.Endpoint,
      https: [
        port: 3001,
        cipher_suite: :strong,
        certfile: secret("wildcard_ssl", dig: [:certificate], to_file: "priv/cert/cert.pem"),
        keyfile: secret("wildcard_ssl", dig: [:key], to_file: "priv/cert/key.pem")
      ]
    )

    config :ueberauth, Ueberauth.Strategy.NuSSO, ssl_port: 3001

    if prefix = System.get_env("DEV_PREFIX") do
      config :meadow,
        dc_api: [
          v2: %{
            "api_token_secret" =>
              secret(:meadow, dig: [:dc_api, :v2, :api_token_secret], default: "DEV_SECRET"),
            "api_token_ttl" => 300,
            "base_url" => "https://#{prefix}.dev.rdc.library.northwestern.edu:3002"
          }
        ]
    end
  end
end
