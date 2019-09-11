# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :meadow,
  ecto_repos: [Meadow.Repo]

# Shared database config
config :meadow, Meadow.Repo, migration_primary_key: [name: :id, type: :binary_id]

# Configures the endpoint
config :meadow, MeadowWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "C7BC/yBsTCe/PaJ9g0krwlQrNZZV2r3jSjeuGCeIu9mfNE+4bPcNPHiINQtIQk/B",
  render_errors: [view: MeadowWeb.ErrorView, accepts: ~w(html json)],
  pubsub: [name: Meadow.PubSub, adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

config :ueberauth, Ueberauth,
  providers: [
    openam:
      {Ueberauth.Strategy.OpenAM,
       [
         base_url: "https://websso.it.northwestern.edu/amserver/",
         sso_cookie: "openAMssoToken",
         callback_path: "/auth/openam/callback"
       ]}
  ]

config :honeybadger,
  api_key:
    System.get_env("HONEYBADGER_API_KEY") ||
      "DO_NOT_REPORT",
  environment_name: Mix.env(),
  exclude_envs: [:dev, :test]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
