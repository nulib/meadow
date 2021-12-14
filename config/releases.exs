# In this file, we load production configuration and
# secrets from environment variables. You can also
# hardcode secrets, although such is generally not
# recommended and you have to remember to add this
# file to your .gitignore.
import Config

alias Meadow.Pipeline.Actions

get_required_var = fn var ->
  case System.get_env("__COMPILE_CHECK__") do
    nil -> System.get_env(var) || raise "environment variable #{var} is missing."
    _ -> "COMPILE_CHECK"
  end
end

config :elastix,
  custom_headers:
    {Meadow.Utils.AWS, :add_aws_signature,
     [
       get_required_var.("AWS_REGION"),
       get_required_var.("ELASTICSEARCH_KEY"),
       get_required_var.("ELASTICSEARCH_SECRET")
     ]}

config :exldap, :settings,
  server: get_required_var.("LDAP_SERVER"),
  base: "DC=library,DC=northwestern,DC=edu",
  port: 636,
  ssl: true,
  user_dn: get_required_var.("LDAP_BIND_DN"),
  password: get_required_var.("LDAP_BIND_PASSWORD")

config :meadow, Meadow.Repo,
  url: get_required_var.("DATABASE_URL"),
  pool_size: String.to_integer(System.get_env("DB_POOL_SIZE", "10")),
  queue_target: String.to_integer(System.get_env("DB_QUEUE_TARGET", "50")),
  queue_interval: String.to_integer(System.get_env("DB_QUEUE_INTERVAL", "1000"))

host = System.get_env("MEADOW_HOSTNAME", "example.com")
port = String.to_integer(System.get_env("PORT", "4000"))

config :meadow, MeadowWeb.Endpoint,
  url: [host: host, port: port],
  http: [
    :inet6,
    port: port,
    protocol_options: [
      idle_timeout: :infinity
    ]
  ],
  check_origin: System.get_env("ALLOWED_ORIGINS", "") |> String.split(~r/,\s*/),
  secret_key_base: get_required_var.("SECRET_KEY_BASE"),
  live_view: [signing_salt: get_required_var.("SECRET_KEY_BASE")]

config :meadow, Meadow.ElasticsearchCluster,
  url: get_required_var.("ELASTICSEARCH_URL"),
  api: Elasticsearch.API.AWS,
  default_options: [
    aws: [
      service: "es",
      region: get_required_var.("AWS_REGION"),
      access_key: get_required_var.("ELASTICSEARCH_KEY"),
      secret: get_required_var.("ELASTICSEARCH_SECRET")
    ],
    timeout: 20_000,
    recv_timeout: 90_000
  ],
  json_library: Jason,
  indexes: %{
    meadow: %{
      settings: Meadow.Config.priv_path("elasticsearch/meadow.json"),
      store: Meadow.ElasticsearchStore,
      sources: [
        Meadow.Data.Schemas.Collection,
        Meadow.Data.Schemas.FileSet,
        Meadow.Data.Schemas.Work
      ],
      bulk_page_size:
        System.get_env("ELASTICSEARCH_BULK_PAGE_SIZE", "200") |> String.to_integer(),
      bulk_wait_interval:
        System.get_env("ELASTICSEARCH_BULK_WAIT_INTERVAL", "2000") |> String.to_integer()
    }
  }

config :meadow,
  ark: %{
    default_shoulder: get_required_var.("EZID_SHOULDER"),
    user: get_required_var.("EZID_USER"),
    password: get_required_var.("EZID_PASSWORD"),
    target_url: get_required_var.("EZID_TARGET_BASE_URL")
  },
  environment: :prod,
  digital_collections_url: get_required_var.("DIGITAL_COLLECTIONS_URL"),
  iiif_manifest_url: get_required_var.("IIIF_MANIFEST_URL"),
  iiif_server_url: get_required_var.("IIIF_SERVER_URL"),
  ingest_bucket: get_required_var.("INGEST_BUCKET"),
  mediaconvert_client: MediaConvert,
  mediaconvert_queue: get_required_var.("MEDIACONVERT_QUEUE"),
  mediaconvert_role: get_required_var.("MEDIACONVERT_ROLE"),
  multipart_upload_concurrency: System.get_env("MULTIPART_UPLOAD_CONCURRENCY", "50"),
  pipeline_delay: System.get_env("PIPELINE_DELAY", "120000"),
  preservation_bucket: get_required_var.("PRESERVATION_BUCKET"),
  preservation_check_bucket: get_required_var.("PRESERVATION_CHECK_BUCKET"),
  progress_ping_interval: System.get_env("PROGRESS_PING_INTERVAL", "1000"),
  pyramid_bucket: get_required_var.("PYRAMID_BUCKET"),
  pyramid_tiff_working_dir: System.get_env("PYRAMID_TIFF_WORKING_DIR"),
  sitemaps: [
    gzip: true,
    store: Sitemapper.S3Store,
    store_config: [bucket: get_required_var.("SITEMAP_BUCKET")],
    sitemap_url: get_required_var.("DIGITAL_COLLECTIONS_URL")
  ],
  streaming_bucket: get_required_var.("STREAMING_BUCKET"),
  streaming_url: get_required_var.("STREAMING_URL"),
  upload_bucket: get_required_var.("UPLOAD_BUCKET"),
  validation_ping_interval: System.get_env("VALIDATION_PING_INTERVAL", "1000"),
  work_archiver_endpoint: get_required_var.("WORK_ARCHIVER_ENDPOINT")

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
         base_url: "https://northwestern-prod.apigee.net/agentless-websso/",
         callback_path: "/auth/nusso/callback",
         consumer_key: get_required_var.("AGENTLESS_SSO_KEY"),
         include_attributes: true
       ]}
  ]

config :hackney,
  max_connections: System.get_env("HACKNEY_MAX_CONNECTIONS", "1000") |> String.to_integer()

# Configure Lambda-based actions

config :meadow, :lambda,
  digester: {:lambda, "meadow-digester"},
  exif: {:lambda, "meadow-exif"},
  frame_extractor: {:lambda, "meadow-frame-extractor"},
  mediainfo: {:lambda, "meadow-mediainfo"},
  mime_type: {:lambda, "meadow-mime-type"},
  tiff: {:lambda, "meadow-pyramid-tiff"}

config :sequins, Actions.GenerateFileSetDigests,
  queue_config: [
    producer_concurrency: 10,
    receive_interval: 1000,
    wait_time_seconds: 1,
    max_number_of_messages: 10,
    processor_concurrency: 100,
    visibility_timeout: 360
  ]

config :sequins, Actions.ExtractExifMetadata,
  queue_config: [
    producer_concurrency: 10,
    receive_interval: 1000,
    wait_time_seconds: 1,
    max_number_of_messages: 10,
    processor_concurrency: 100,
    visibility_timeout: 360
  ]

config :sequins, Actions.ExtractMediaMetadata,
  queue_config: [
    producer_concurrency: 10,
    receive_interval: 1000,
    wait_time_seconds: 1,
    max_number_of_messages: 10,
    processor_concurrency: 100,
    visibility_timeout: 360
  ]

config :sequins, Actions.ExtractMimeType,
  queue_config: [
    producer_concurrency: 10,
    receive_interval: 1000,
    wait_time_seconds: 1,
    max_number_of_messages: 10,
    processor_concurrency: 100,
    visibility_timeout: 120
  ]

config :sequins, Actions.CreatePyramidTiff,
  queue_config: [
    producer_concurrency: 10,
    receive_interval: 1000,
    wait_time_seconds: 1,
    max_number_of_messages: 10,
    processor_concurrency: 100,
    visibility_timeout: 360
  ]

config :sequins, Actions.CreateTranscodeJob,
  queue_config: [
    producer_concurrency: 10,
    receive_interval: 1000,
    wait_time_seconds: 1,
    max_number_of_messages: 10,
    processor_concurrency: 100,
    visibility_timeout: 360
  ]

config :sequins, Actions.TranscodeComplete,
  queue_config: [
    producer_concurrency: 10,
    receive_interval: 1000,
    wait_time_seconds: 1,
    max_number_of_messages: 10,
    processor_concurrency: 100,
    visibility_timeout: 360
  ]
