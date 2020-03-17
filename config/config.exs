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
config :meadow, Meadow.Repo,
  migration_primary_key: [
    name: :id,
    type: :binary_id,
    autogenerate: false,
    read_after_writes: true,
    default: {:fragment, "uuid_generate_v4()"}
  ],
  migration_timestamps: [type: :utc_datetime_usec]

# Configures the endpoint
config :meadow, MeadowWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "C7BC/yBsTCe/PaJ9g0krwlQrNZZV2r3jSjeuGCeIu9mfNE+4bPcNPHiINQtIQk/B",
  render_errors: [view: MeadowWeb.ErrorView, accepts: ~w(html json)],
  pubsub: [name: Meadow.PubSub, adapter: Phoenix.PubSub.PG2]

# Configures the ElasticsearchCluster
config :meadow, Meadow.ElasticsearchCluster,
  api: Elasticsearch.API.HTTP,
  json_library: Jason,
  indexes: %{
    meadow: %{
      settings: "priv/elasticsearch/meadow.json",
      store: Meadow.ElasticsearchStore,
      sources: [
        Meadow.Data.Schemas.Collection,
        Meadow.Data.Schemas.FileSet,
        Meadow.Data.Schemas.Work
      ],
      bulk_page_size: 5_000,
      bulk_wait_interval: 2_000
    }
  }

# Configures the pyramid TIFF processor
with val <- System.get_env("PYRAMID_PROCESSOR") do
  unless is_nil(val), do: config(:meadow, pyramid_processor: val)
end

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $levelpad$message\n",
  metadata: [:request_id, :action]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

config :honeybadger,
  api_key:
    System.get_env("HONEYBADGER_API_KEY") ||
      "DO_NOT_REPORT",
  environment_name: Mix.env(),
  exclude_envs: [:dev, :test]

aws_env =
  System.get_env(
    "AWS_PROFILE",
    System.get_env("AWS_DEFAULT_PROFILE", "default")
  )

aws_region =
  System.get_env(
    "AWS_REGION",
    System.get_env("AWS_DEFAULT_REGION", "us-east-1")
  )

config :ex_aws,
  access_key_id: [{:system, "AWS_ACCESS_KEY_ID"}, {:awscli, aws_env, 30}, :instance_role],
  secret_access_key: [
    {:system, "AWS_SECRET_ACCESS_KEY"},
    {:awscli, aws_env, 30},
    :instance_role
  ],
  region: aws_region

import_config "sequins.exs"

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"

if File.exists?("config/#{Mix.env()}.local.exs"),
  do: import_config("#{Mix.env()}.local.exs")
