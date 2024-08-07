import Config
import Env

alias Hush.Provider.AwsSecretsManager

File.mkdir_p!("priv/cert")

config :meadow, Meadow.Repo,
  show_sensitive_data_on_connection_error: true,
  timeout: 60_000,
  connect_timeout: 60_000,
  handshake_timeout: 60_000,
  pool_size: 50

config :meadow, MeadowWeb.Endpoint,
  https: [
    port: 3001,
    cipher_suite: :strong,
    certfile:
      aws_secret("wildcard_ssl",
        apply: &{:ok, Map.get(&1, "certificate")},
        to_file: "priv/cert/cert.pem"
      ),
    keyfile:
      aws_secret("wildcard_ssl", apply: &{:ok, Map.get(&1, "key")}, to_file: "priv/cert/key.pem")
  ],
  debug_errors: false,
  code_reloader: true,
  check_origin: false,
  watchers: [
    node: [
      "build.js",
      "--watch",
      cd: Path.expand("../assets", __DIR__)
    ]
  ],
  live_reload: [
    patterns: [
      ~r"priv/static/.*(js|css|png|jpeg|jpg|gif|svg)$",
      ~r"priv/gettext/.*(po)$",
      ~r"lib/meadow_web/{live,views}/.*(ex)$",
      ~r"lib/meadow_web/templates/.*(eex)$"
    ]
  ]

if System.get_env("AWS_DEV_ENVIRONMENT") |> is_nil() do
  # Configures lambda scripts
  config :meadow, :lambda,
    digester: {:local, {Path.expand("../lambdas/digester/index.js"), "handler"}},
    exif: {:local, {Path.expand("../lambdas/exif/index.js"), "handler"}},
    frame_extractor: {:local, {Path.expand("../lambdas/frame-extractor/index.js"), "handler"}},
    mediainfo: {:local, {Path.expand("../lambdas/mediainfo/index.js"), "handler"}},
    mime_type: {:local, {Path.expand("../lambdas/mime-type/index.js"), "handler"}},
    tiff: {:local, {Path.expand("../lambdas/pyramid-tiff/index.js"), "handler"}}

  config :meadow,
    checksum_notification: %{
      arn: "arn:aws:lambda:us-east-1:000000000000:function:digest-tag",
      buckets: ["dev-ingest", "dev-uploads"]
    },
    mediaconvert_client: MediaConvert.Mock

  [:mediaconvert, :s3, :secretsmanager, :sns, :sqs]
  |> Enum.each(fn service ->
    config :ex_aws, service,
      scheme: "https://",
      host: "localhost.localstack.cloud",
      port: 4566,
      access_key_id: "fake",
      secret_access_key: "fake",
      region: "us-east-1"
  end)
end

config :meadow,
  index_interval: 30_000,
  mediaconvert_queue: prefix("transcode"),
  mediaconvert_role: aws_secret("meadow", dig: ["transcode", "role_arn"])

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

config :ueberauth, Ueberauth,
  providers: [
    nusso:
      {Ueberauth.Strategy.NuSSO,
       [
         base_url: aws_secret("meadow", dig: ["nusso", "base_url"]),
         callback_path: "/auth/nusso/callback",
         callback_port: 3001,
         consumer_key: aws_secret("meadow", dig: ["nusso", "api_key"]),
         include_attributes: false,
         ssl_port: 3001
       ]}
  ]

if prefix = System.get_env("DEV_PREFIX") do
  config :meadow,
    dc_api: [
      v2: %{
        "api_token_secret" =>
          aws_secret("meadow", dig: ["dc_api", "v2", "api_token_secret"], default: "DEV_SECRET"),
        "api_token_ttl" => 300,
        "base_url" => "https://#{prefix}.dev.rdc.library.northwestern.edu:3002"
      }
    ]
end

config :meadow, :sitemaps,
  base_url: "https://dc.library.northwestern.edu/",
  gzip: false,
  store: Sitemapper.FileStore,
  sitemap_url: "https://devbox.library.northwestern.edu:3333/",
  store_config: [path: "priv/static"]
