# In this file, we load production configuration and
# secrets from environment variables. You can also
# hardcode secrets, although such is generally not
# recommended and you have to remember to add this
# file to your .gitignore.
import Config
import Env

alias Meadow.Pipeline.Actions

[:hackney, :ex_aws] |> Enum.each(&Application.ensure_all_started/1)

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
       environment_secret("AWS_REGION"),
       aws_secret("meadow", dig: ["search", "access_key_id"]),
       aws_secret("meadow", dig: ["search", "secret_access_key"])
     ]}

config :exldap, :settings,
  port: 636,
  ssl: true

config :meadow, Meadow.Repo,
  pool_size: environment_secret("DB_POOL_SIZE", cast: :integer, default: 10),
  queue_target: environment_secret("DB_QUEUE_TARGET", cast: :integer, default: 50),
  queue_interval: environment_secret("DB_QUEUE_INTERVAL", cast: :integer, default: 1000)

host = environment_secret("MEADOW_HOSTNAME", default: "example.com")
port = environment_secret("PORT", cast: :integer, default: 4000)

config :meadow, MeadowWeb.Endpoint,
  url: [host: host, port: port],
  http: [
    :inet6,
    port: port,
    protocol_options: [
      idle_timeout: :infinity,
      max_header_value_length: 8192
    ]
  ],
  check_origin: environment_secret("ALLOWED_ORIGINS", split: ~r/,\s*/, default: ""),
  secret_key_base: environment_secret("SECRET_KEY_BASE"),
  live_view: [signing_salt: environment_secret("SECRET_KEY_BASE")]

config :meadow, Meadow.Search.Cluster,
  default_options: [
    aws: [
      service: "es",
      region: environment_secret("AWS_REGION"),
      access_key: aws_secret("meadow", dig: ["search", "access_key_id"]),
      secret: aws_secret("meadow", dig: ["search", "secret_access_key"])
    ],
    timeout: 20_000,
    recv_timeout: 90_000
  ],
  bulk_page_size: 200,
  bulk_wait_interval: 500,
  json_library: Jason,
  indexes: [
    %{
      name: "dc-v2-work",
      settings: priv_path.("search/v2/settings/work.json"),
      version: 2,
      schemas: [Meadow.Data.Schemas.Work],
      pipeline: prefix("dc-v2-work-pipeline")
    },
    %{
      name: "dc-v2-file-set",
      settings: priv_path.("search/v2/settings/file_set.json"),
      version: 2,
      schemas: [Meadow.Data.Schemas.FileSet]
    },
    %{
      name: "dc-v2-collection",
      settings: priv_path.("search/v2/settings/collection.json"),
      version: 2,
      schemas: [Meadow.Data.Schemas.Collection]
    }
  ]

config :meadow,
  environment: :prod,
  environment_prefix: nil,
  mediaconvert_client: MediaConvert,
  mediaconvert_queue: aws_secret("meadow", dig: ["mediaconvert", "queue"]),
  mediaconvert_role: aws_secret("meadow", dig: ["mediaconvert", "role_arn"]),
  multipart_upload_concurrency: environment_secret("MULTIPART_UPLOAD_CONCURRENCY", default: "50"),
  pipeline_delay: environment_secret("PIPELINE_DELAY", default: "120000"),
  progress_ping_interval: environment_secret("PROGRESS_PING_INTERVAL", default: "1000"),
  shared_links_index: "shared_links",
  sitemaps: [
    gzip: true,
    store: Sitemapper.S3Store,
    store_config: [
      bucket: aws_secret("meadow", dig: ["buckets", "sitemap"]),
      path: "/"
    ],
    sitemap_url: aws_secret("meadow", dig: ["dc", "base_url"])
  ],
  validation_ping_interval: environment_secret("VALIDATION_PING_INTERVAL", default: "1000")

config :meadow,
  ingest_bucket: aws_secret("meadow", dig: ["buckets", "ingest"]),
  preservation_bucket: aws_secret("meadow", dig: ["buckets", "preservation"]),
  pyramid_bucket: aws_secret("meadow", dig: ["buckets", "pyramid"]),
  upload_bucket: aws_secret("meadow", dig: ["buckets", "upload"]),
  preservation_check_bucket: aws_secret("meadow", dig: ["buckets", "preservation_check"]),
  streaming_bucket: aws_secret("meadow", dig: ["buckets", "streaming"])

config :meadow, :livebook, url: environment_secret("LIVEBOOK_URL", default: nil)

config :logger, level: :info

config :meadow, Meadow.Scheduler,
  overlap: false,
  timezone: "America/Chicago",
  jobs: [
    # Runs daily at the configured time (default: 2AM Central)
    {
      aws_secret("meadow", dig: ["scheduler", "preservation_check"], default: "0 2 * * *"),
      {Meadow.Data.PreservationChecks, :start_job, []}
    }
  ]

config :ueberauth, Ueberauth,
  providers: [
    nusso:
      {Ueberauth.Strategy.NuSSO,
       [
         base_url:
           aws_secret("meadow",
             dig: ["nusso", "base_url"],
             default: "https://northwestern-prod.apigee.net/agentless-websso/"
           ),
         callback_path: "/auth/nusso/callback",
         consumer_key: aws_secret("meadow", dig: ["nusso", "api_key"]),
         include_attributes: false
       ]}
  ]

config :hackney,
  max_connections: environment_secret("HACKNEY_MAX_CONNECTIONS", cast: :integer, default: "1000")

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
    config :meadow,
           Meadow.Pipeline,
           [
             {action,
              producer: [
                receive_interval: receive_interval,
                wait_time_seconds: wait_time_seconds,
                max_number_of_messages: max_number_of_messages,
                visibility_timeout:
                  environment_secret("#{key}_VISIBILITY_TIMEOUT", cast: :integer, default: 300)
              ],
              processors: [
                default: [
                  concurrency:
                    environment_secret("#{key}_PROCESSOR_CONCURRENCY",
                      cast: :integer,
                      default: 10
                    ),
                  max_demand:
                    environment_secret("#{key}_MAX_DEMAND", cast: :integer, default: 10),
                  min_demand: environment_secret("#{key}_MIN_DEMAND", cast: :integer, default: 5)
                ]
              ]}
           ]
  end
end)

config :authoritex, geonames_username: aws_secret("meadow", dig: ["geonames", "username"])
