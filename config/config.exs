# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :elixir, :time_zone_database, Tzdata.TimeZoneDatabase

config :meadow,
  ecto_repos: [Meadow.Repo],
  environment: Mix.env()

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
  pubsub_server: Meadow.PubSub,
  live_view: [signing_salt: "C7BC/yBsTCe/PaJ9g0krwlQrNZZV2r3jSjeuGCeIu9mfNE+4bPcNPHiINQtIQk/B"]

# Configures the ElasticsearchCluster
config :meadow, Meadow.ElasticsearchCluster,
  api: Elasticsearch.API.HTTP,
  default_options: [
    timeout: 20_000,
    recv_timeout: 30_000
  ],
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
      bulk_page_size: 200,
      bulk_wait_interval: 500
    }
  }

# Configures lambda scripts
config :meadow, :lambda,
  digester: {:local, {"nodejs/digester/index.js", "handler"}},
  edtf: {:local, {"nodejs/edtf/index.js", "handler"}},
  exif: {:local, {"nodejs/exif/index.js", "handler"}},
  frame_extractor: {:local, {"nodejs/frame-extractor/index.js", "handler"}},
  mediainfo: {:local, {"nodejs/mediainfo/index.js", "handler"}},
  mime_type: {:local, {"nodejs/mime-type/index.js", "handler"}},
  tiff: {:local, {"nodejs/pyramid-tiff/index.js", "handler"}}

config :meadow,
  transcoding_presets: %{
    audio: [
      %{NameModifier: "-high", Preset: "meadow-audio-high"},
      %{NameModifier: "-medium", Preset: "meadow-audio-medium"}
    ],
    video: [
      %{NameModifier: "-1080", Preset: "System-Avc_16x9_1080p_29_97fps_8500kbps"},
      %{NameModifier: "-720", Preset: "System-Avc_16x9_720p_29_97fps_5000kbps"},
      %{NameModifier: "-540", Preset: "System-Avc_16x9_540p_29_97fps_3500kbps"}
    ]
  }

# Configures the pyramid TIFF processor
with val <- System.get_env("PYRAMID_PROCESSOR") do
  unless is_nil(val), do: config(:meadow, pyramid_processor: val)
end

# Configures the ETDF parser
with val <- System.get_env("EDTF") do
  unless is_nil(val), do: config(:meadow, edtf: val)
end

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $levelpad$message\n",
  metadata: [:request_id, :module, :id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

config :ueberauth, Ueberauth, providers: [nusso: {Ueberauth.Strategy.NuSSO, []}]

config :authoritex,
  authorities: [
    Authoritex.FAST.CorporateName,
    Authoritex.FAST.EventName,
    Authoritex.FAST.Form,
    Authoritex.FAST.Geographic,
    Authoritex.FAST.Personal,
    Authoritex.FAST.Topical,
    Authoritex.FAST.UniformTitle,
    Authoritex.FAST,
    Authoritex.GeoNames,
    Authoritex.Getty.AAT,
    Authoritex.Getty.TGN,
    Authoritex.Getty.ULAN,
    Authoritex.Getty,
    Authoritex.LOC.Languages,
    Authoritex.LOC.Names,
    Authoritex.LOC.SubjectHeadings,
    NUL.Authority
  ]

config :honeybadger,
  api_key: System.get_env("HONEYBADGER_API_KEY", "DO_NOT_REPORT"),
  environment_name: System.get_env("HONEYBADGER_ENVIRONMENT", to_string(Mix.env())),
  revision: System.get_env("HONEYBADGER_REVISION", nil),
  repos: [Meadow.Repo],
  breadcrumbs_enabled: true,
  filter: Meadow.Error.Filter,
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

config :httpoison_retry, wait: 50

config :mime, :types, %{
  "video/x-m4v" => ["m4v"],
  "video/x-matroska" => ["mkv"],
  "audio/x-aiff" => ["aif","aiff","aifc"]
}

import_config "sequins.exs"

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"

if File.exists?("config/#{Mix.env()}.local.exs"),
  do: import_config("#{Mix.env()}.local.exs")
