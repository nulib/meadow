# In this file, we load production configuration and
# secrets from environment variables. You can also
# hardcode secrets, although such is generally not
# recommended and you have to remember to add this
# file to your .gitignore.
import Config

alias Meadow.Pipeline.Actions
alias Hush.Provider.{AwsSecretsManager, SystemEnvironment}

if Hush.release_mode?(), do: [:hackney, :ex_aws] |> Enum.each(&Application.ensure_all_started/1)

secrets_path = System.get_env("SECRETS_PATH", "config")
meadow_secrets = [secrets_path, "meadow"] |> Enum.reject(&is_nil/1) |> Enum.join("/")

priv_path = fn path ->
  case :code.priv_dir(:meadow) do
    {:error, :bad_name} -> Path.join([".", "priv", path])
    priv_dir -> priv_dir |> to_string() |> Path.join(path)
  end
end

config :elastix,
  custom_headers:
    {Meadow.Utils.AWS, :add_aws_signature,
     [
       {:hush, SystemEnvironment, "AWS_REGION"},
       {:hush, AwsSecretsManager, meadow_secrets, dig: ["index", "access_key_id"]},
       {:hush, AwsSecretsManager, meadow_secrets, dig: ["index", "secret_access_key"]}
     ]}

config :exldap, :settings,
  port: 636,
  ssl: true

config :meadow, Meadow.Repo,
  pool_size: {:hush, SystemEnvironment, "DB_POOL_SIZE", cast: :integer, default: 10},
  queue_target: {:hush, SystemEnvironment, "DB_QUEUE_TARGET", cast: :integer, default: 50},
  queue_interval: {:hush, SystemEnvironment, "DB_QUEUE_INTERVAL", cast: :integer, default: 1000}

host = {:hush, SystemEnvironment, "MEADOW_HOSTNAME", default: "example.com"}
port = {:hush, SystemEnvironment, "PORT", cast: :integer, default: 4000}

config :meadow, MeadowWeb.Endpoint,
  url: [host: host, port: port],
  http: [
    :inet6,
    port: port,
    protocol_options: [
      idle_timeout: :infinity
    ]
  ],
  check_origin: {:hush, SystemEnvironment, "ALLOWED_ORIGINS", split: ~r/,\s*/, default: ""},
  secret_key_base: {:hush, SystemEnvironment, "SECRET_KEY_BASE"},
  live_view: [signing_salt: {:hush, SystemEnvironment, "SECRET_KEY_BASE"}]

config :meadow, Meadow.SearchIndex, primary_index: :meadow

config :meadow, Meadow.ElasticsearchCluster,
  api: Elasticsearch.API.AWS,
  default_options: [
    aws: [
      service: "es",
      region: {:hush, SystemEnvironment, "AWS_REGION"},
      access_key: {:hush, AwsSecretsManager, meadow_secrets, dig: ["index", "access_key_id"]},
      secret: {:hush, AwsSecretsManager, meadow_secrets, dig: ["index", "secret_access_key"]}
    ],
    timeout: 20_000,
    recv_timeout: 90_000
  ],
  json_library: Jason,
  indexes: %{
    :meadow => %{
      settings: priv_path.("elasticsearch/v1/settings/meadow.json"),
      store: Meadow.ElasticsearchStore,
      sources: [
        Meadow.Data.Schemas.Collection,
        Meadow.Data.Schemas.FileSet,
        Meadow.Data.Schemas.Work
      ],
      bulk_page_size: 200,
      bulk_wait_interval: 2000
    },
    :"dc-v2-work" => %{
      settings: priv_path.("elasticsearch/v2/settings/work.json"),
      store: Meadow.ElasticsearchEmptyStore,
      sources: [:nothing],
      bulk_page_size: 200,
      bulk_wait_interval: 500,
      default_pipeline: "v1-to-v2-work"
    },
    :"dc-v2-file-set" => %{
      settings: priv_path.("elasticsearch/v2/settings/file_set.json"),
      store: Meadow.ElasticsearchEmptyStore,
      sources: [:nothing],
      bulk_page_size: 200,
      bulk_wait_interval: 500,
      default_pipeline: "v1-to-v2-file-set"
    },
    :"dc-v2-collection" => %{
      settings: priv_path.("elasticsearch/v2/settings/collection.json"),
      store: Meadow.ElasticsearchEmptyStore,
      sources: [:nothing],
      bulk_page_size: 200,
      bulk_wait_interval: 500,
      default_pipeline: "v1-to-v2-collection"
    }
  }

config :meadow,
  environment: :prod,
  environment_prefix: nil,
  mediaconvert_client: MediaConvert,
  mediaconvert_queue: {:hush, AwsSecretsManager, meadow_secrets, dig: ["mediaconvert", "queue"]},
  mediaconvert_role:
    {:hush, AwsSecretsManager, meadow_secrets, dig: ["mediaconvert", "role_arn"]},
  multipart_upload_concurrency:
    {:hush, SystemEnvironment, "MULTIPART_UPLOAD_CONCURRENCY", default: "50"},
  pipeline_delay: {:hush, SystemEnvironment, "PIPELINE_DELAY", default: "120000"},
  progress_ping_interval: {:hush, SystemEnvironment, "PROGRESS_PING_INTERVAL", default: "1000"},
  shared_links_index: "shared_links",
  sitemaps: [
    gzip: true,
    store: Sitemapper.S3Store,
    store_config: [
      bucket: {:hush, AwsSecretsManager, meadow_secrets, dig: ["buckets", "sitemap"]}
    ],
    sitemap_url: {:hush, AwsSecretsManager, meadow_secrets, dig: ["dc", "base_url"]}
  ],
  validation_ping_interval:
    {:hush, SystemEnvironment, "VALIDATION_PING_INTERVAL", default: "1000"}

config :meadow,
  ingest_bucket: {:hush, AwsSecretsManager, meadow_secrets, dig: ["buckets", "ingest"]},
  preservation_bucket:
    {:hush, AwsSecretsManager, meadow_secrets, dig: ["buckets", "preservation"]},
  pyramid_bucket: {:hush, AwsSecretsManager, meadow_secrets, dig: ["buckets", "pyramid"]},
  upload_bucket: {:hush, AwsSecretsManager, meadow_secrets, dig: ["buckets", "upload"]},
  preservation_check_bucket:
    {:hush, AwsSecretsManager, meadow_secrets, dig: ["buckets", "preservation_check"]},
  streaming_bucket: {:hush, AwsSecretsManager, meadow_secrets, dig: ["buckets", "streaming"]}

config :logger, level: :info

config :meadow, Meadow.Scheduler,
  overlap: false,
  timezone: "America/Chicago",
  jobs: [
    # Runs daily at 2AM Central Time
    {"0 2 * * *", {Meadow.Data.PreservationChecks, :start_job, []}}
  ]

config :sequins,
  prefix: "meadow",
  supervisor_opts: [max_restarts: 2048]

config :ueberauth, Ueberauth,
  providers: [
    nusso:
      {Ueberauth.Strategy.NuSSO,
       [
         base_url:
           {:hush, AwsSecretsManager, meadow_secrets,
            dig: ["nusso", "base_url"],
            default: "https://northwestern-prod.apigee.net/agentless-websso/"},
         callback_path: "/auth/nusso/callback",
         consumer_key: {:hush, AwsSecretsManager, meadow_secrets, dig: ["nusso", "api_key"]},
         include_attributes: false
       ]}
  ]

config :hackney,
  max_connections:
    {:hush, SystemEnvironment, "HACKNEY_MAX_CONNECTIONS", cast: :integer, default: "1000"}

[
  {Actions.IngestFileSet, "INGEST_FILE_SET"},
  {Actions.ExtractMimeType, "EXTRACT_MIME_TYPE"},
  {Actions.InitializeDispatch, "INITIALIZE_DISPATCH"},
  {Actions.Dispatcher, "DISPATCHER"},
  {Actions.GenerateFileSetDigests, "GENERATE_FILE_SET_DIGESTS"},
  {Actions.ExtractExifMetadata, "EXTRACT_EXIF_METADATA"},
  {Actions.CopyFileToPreservation, "COPY_FILE_TO_PRESERVATION"},
  {Actions.CreatePyramidTiff, "CREATE_PYRAMID_TIFF"},
  {Actions.ExtractMediaMetadata, "EXTRACT_MEDIA_METADATA"},
  {Actions.CreateTranscodeJob, "CREATE_TRANSCODE_JOB"},
  {Actions.TranscodeComplete, "TRANSCODE_COMPLETE"},
  {Actions.GeneratePosterImage, "GENERATE_POSTER_IMAGE"},
  {Actions.FileSetComplete, "FILE_SET_COMPLETE"}
]
|> Enum.each(fn {action, key} ->
  with receive_interval <- 1000,
       wait_time_seconds <- 1,
       max_number_of_messages <- 10 do
    config :sequins, action,
      queue_config: [
        producer_concurrency: 1,
        receive_interval: receive_interval,
        wait_time_seconds: wait_time_seconds,
        max_number_of_messages: max_number_of_messages,
        processor_concurrency:
          {:hush, SystemEnvironment, "#{key}_PROCESSOR_CONCURRENCY", cast: :integer, default: 10},
        visibility_timeout:
          {:hush, SystemEnvironment, "#{key}_VISIBILITY_TIMEOUT", cast: :integer, default: 300},
        max_demand: {:hush, SystemEnvironment, "#{key}_MAX_DEMAND", cast: :integer, default: 10},
        min_demand: {:hush, SystemEnvironment, "#{key}_MIN_DEMAND", cast: :integer, default: 5}
      ]
  end
end)
