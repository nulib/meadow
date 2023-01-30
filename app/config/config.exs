# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config
import Env

alias Meadow.Utils.Hush.Transformer, as: CustomTransformer

config :elixir, :time_zone_database, Tzdata.TimeZoneDatabase

config :meadow,
  ecto_repos: [Meadow.Repo],
  environment: Mix.env(),
  environment_prefix: prefix()

config :meadow, Meadow.Repo,
  migration_primary_key: [
    name: :id,
    type: :binary_id,
    autogenerate: false,
    read_after_writes: true,
    default: {:fragment, "uuid_generate_v4()"}
  ],
  migration_timestamps: [type: :utc_datetime_usec],
  username: aws_secret("meadow", dig: ["db", "user"], default: "docker"),
  password: aws_secret("meadow", dig: ["db", "password"], default: "d0ck3r"),
  database: aws_secret("meadow", dig: ["db", "database"], default: prefix("meadow")),
  hostname: aws_secret("meadow", dig: ["db", "host"], default: "localhost"),
  port: aws_secret("meadow", dig: ["db", "port"], default: 5432)

# Configures the endpoint
config :meadow, MeadowWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "C7BC/yBsTCe/PaJ9g0krwlQrNZZV2r3jSjeuGCeIu9mfNE+4bPcNPHiINQtIQk/B",
  render_errors: [view: MeadowWeb.ErrorView, accepts: ~w(html json)],
  pubsub_server: Meadow.PubSub,
  live_view: [signing_salt: "C7BC/yBsTCe/PaJ9g0krwlQrNZZV2r3jSjeuGCeIu9mfNE+4bPcNPHiINQtIQk/B"]

# Configures the Search cluster
config :meadow, Meadow.Search.Cluster,
  url:
    aws_secret("meadow",
      dig: ["search", "cluster_endpoint"],
      default: "http://localhost:9201"
    ),
  indexes: [
    %{
      name: prefix("meadow"),
      settings: "priv/search/v1/settings/meadow.json",
      version: 1,
      schemas: [
        Meadow.Data.Schemas.Collection,
        Meadow.Data.Schemas.FileSet,
        Meadow.Data.Schemas.Work
      ]
    },
    %{
      name: prefix("dc-v2-work"),
      settings: "priv/search/v2/settings/work.json",
      version: 2,
      schemas: [Meadow.Data.Schemas.Work]
    },
    %{
      name: prefix("dc-v2-file-set"),
      settings: "priv/search/v2/settings/file_set.json",
      version: 2,
      schemas: [Meadow.Data.Schemas.FileSet]
    },
    %{
      name: prefix("dc-v2-collection"),
      settings: "priv/search/v2/settings/collection.json",
      version: 2,
      schemas: [Meadow.Data.Schemas.Collection]
    }
  ],
  default_options: [
    timeout: 20_000,
    recv_timeout: 30_000
  ],
  bulk_page_size: 200,
  bulk_wait_interval: 500,
  json_encoder: Ecto.Jason

config :meadow,
  ark: %{
    default_shoulder: aws_secret("meadow", dig: ["ezid", "shoulder"], default: "ark:/12345/nu1"),
    user: aws_secret("meadow", dig: ["ezid", "user"], default: "ark_user"),
    password: aws_secret("meadow", dig: ["ezid", "password"], default: "ark_password"),
    target_url:
      aws_secret("meadow",
        dig: ["ezid", "target_base_url"],
        default: "https://devbox.library.northwestern.edu:3333/items/"
      ),
    url: aws_secret("meadow", dig: ["ezid", "url"], default: "http://localhost:3943")
  },
  ingest_bucket: prefix("ingest"),
  upload_bucket: prefix("uploads"),
  pipeline_delay: :timer.seconds(5),
  preservation_bucket: prefix("preservation"),
  preservation_check_bucket: prefix("preservation-checks"),
  pyramid_bucket: prefix("pyramids"),
  streaming_bucket: prefix("streaming"),
  streaming_url:
    aws_secret("meadow",
      dig: ["streaming", "base_url"],
      default: "https://#{prefix()}-streaming.s3.amazonaws.com/"
    ),
  mediaconvert_client: MediaConvert.Mock,
  multipart_upload_concurrency: System.get_env("MULTIPART_UPLOAD_CONCURRENCY", "10"),
  iiif_server_url:
    aws_secret("meadow",
      dig: ["iiif", "base_url"],
      default: "https://iiif.dev.rdc.library.northwestern.edu/iiif/2/#{prefix()}"
    ),
  iiif_manifest_url:
    aws_secret("meadow",
      dig: ["iiif", "manifest_url"],
      default: "https://#{prefix()}-pyramids.s3.amazonaws.com/public/"
    ),
  iiif_distribution_id: aws_secret("meadow", dig: ["iiif", "distribution_id"], default: nil),
  digital_collections_url:
    aws_secret("meadow",
      dig: ["dc", "base_url"],
      default: "https://dc.rdc-staging.library.northwestern.edu/"
    ),
  progress_ping_interval: System.get_env("PROGRESS_PING_INTERVAL", "1000"),
  validation_ping_interval: System.get_env("VALIDATION_PING_INTERVAL", "1000"),
  shared_links_index: prefix("shared_links"),
  pyramid_tiff_working_dir: System.tmp_dir!(),
  work_archiver_endpoint: aws_secret("meadow", dig: ["work_archiver", "endpoint"], default: "")

config :exldap, :settings,
  server: aws_secret("meadow", dig: ["ldap", "host"], default: "localhost"),
  base:
    aws_secret("meadow",
      dig: ["ldap", "base"],
      default: "DC=library,DC=northwestern,DC=edu"
    ),
  port: aws_secret("meadow", dig: ["ldap", "port"], cast: :integer, default: 390),
  user_dn:
    aws_secret("meadow",
      dig: ["ldap", "user_dn"],
      default: "cn=Administrator,cn=Users,dc=library,dc=northwestern,dc=edu"
    ),
  password: aws_secret("meadow", dig: ["ldap", "password"], default: "d0ck3rAdm1n!"),
  ssl: aws_secret("meadow", dig: ["ldap", "ssl"], cast: :boolean, default: false)

config :meadow,
  transcoding_presets: %{
    audio: [
      %{NameModifier: "-high", Preset: "meadow-audio-high"},
      %{NameModifier: "-medium", Preset: "meadow-audio-medium"}
    ],
    video: [
      %{NameModifier: "-1080", Preset: "meadow-video-high"},
      %{NameModifier: "-720", Preset: "meadow-video-medium"},
      %{NameModifier: "-540", Preset: "meadow-video-low"}
    ]
  }

# Configure checksum requirements
config :meadow,
  required_checksum_tags: ["computed-md5"],
  checksum_wait_timeout: 3_600_000

# Configure Lambda-based actions
lambda_from_ssm = fn lambda, function ->
  {:lambda, aws_secret("meadow", dig: ["pipeline", lambda], default: "#{function}:$LATEST")}
end

config :meadow, :lambda,
  digester: lambda_from_ssm.("digester", "digester"),
  exif: lambda_from_ssm.("exif", "exif"),
  frame_extractor: lambda_from_ssm.("frame_extractor", "frame-extractor"),
  mediainfo: lambda_from_ssm.("mediainfo", "mediainfo"),
  mime_type: lambda_from_ssm.("mime_type", "mime-type"),
  tiff: lambda_from_ssm.("tiff", "pyramid-tiff")

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
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
  api_key: environment_secret("HONEYBADGER_API_KEY", default: "DO_NOT_REPORT"),
  environment_name: System.get_env("HONEYBADGER_ENVIRONMENT", to_string(Mix.env())),
  revision: System.get_env("HONEYBADGER_REVISION", ""),
  repos: [Meadow.Repo],
  breadcrumbs_enabled: true,
  filter: Meadow.Error.Filter,
  exclude_envs: [:dev, :test]

config :ex_aws,
  access_key_id: [:instance_role],
  secret_access_key: [:instance_role],
  region: System.get_env("AWS_REGION", "us-east-1")

config :httpoison_retry, wait: 50

config :meadow, :extra_mime_types, %{
  "aif" => "audio/x-aiff",
  "aifc" => "audio/x-aiff",
  "aiff" => "audio/x-aiff",
  "flac" => "audio/x-flac",
  "framemd5" => "text/plain",
  "m4v" => "video/x-m4v",
  "md5" => "text/plain",
  "mkv" => "video/x-matroska",
  "mts" => "video/x-mts",
  "vob" => "video/x-vob",
  # package defaults to "text/xml"
  "xml" => "application/xml"
}

config :meadow,
  dc_api: [
    v2: aws_secret("meadow", dig: ["dc_api", "v2"], default: "http://localhost:3000")
  ]

config :hush,
  transformers_override: true,
  transformers: [
    CustomTransformer.Dig,
    CustomTransformer.Default,
    CustomTransformer.Split,
    Hush.Transformer.Apply,
    CustomTransformer.Cast,
    Hush.Transformer.ToFile
  ]

import_config "pipeline.exs"

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.

import_config("#{Mix.env()}.exs")

if File.exists?("config/#{Mix.env()}.local.exs"),
  do: import_config("#{Mix.env()}.local.exs")
