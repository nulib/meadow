import Config

prefix = [System.get_env("DEV_PREFIX"), Mix.env()] |> Enum.reject(&is_nil/1) |> Enum.join("-")

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :meadow, MeadowWeb.Endpoint,
  http: [port: 4002],
  server: false

config :meadow, Meadow.ElasticsearchCluster,
  indexes: %{
    :"#{prefix}-meadow" => %{
      settings: "priv/elasticsearch/v1/settings/meadow.json",
      store: Meadow.ElasticsearchStore,
      sources: [
        Meadow.Data.Schemas.Collection,
        Meadow.Data.Schemas.FileSet,
        Meadow.Data.Schemas.Work
      ],
      bulk_page_size: 3,
      bulk_wait_interval: 2
    }
  }

config :meadow,
  index_interval: 1234,
  mediaconvert_client: MediaConvert.Mock,
  streaming_url: "https://test-streaming-url/",
  iiif_server_url: "http://localhost:8184/iiif/2/",
  iiif_manifest_url: "http://test-pyramids.s3.localhost.localstack.cloud:4568/public/",
  digital_collections_url: "https://fen.rdc-staging.library.northwestern.edu/"

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
    buckets: ["test-ingest", "test-uploads"]
  },
  required_checksum_tags: ["computed-md5"],
  checksum_wait_timeout: 15_000

config :meadow,
  ark: %{
    default_shoulder: "ark:/12345/nu2",
    user: "mockuser",
    password: "mockpassword",
    target_url: "https://devbox.library.northwestern.edu:3333/items/",
    url: "http://localhost:3944/"
  }

config :meadow, :elasticsearch_retry,
  interval: 100,
  max_retries: 3

config :authoritex, authorities: [Authoritex.Mock, NUL.Authority]

config :ueberauth, Ueberauth,
  providers: [
    nusso:
      {Ueberauth.Strategy.NuSSO,
       [
         base_url: "https://northwestern-dev.apigee.net/agentless-websso/",
         callback_path: "/auth/nusso/callback",
         consumer_key: "test-sso-key",
         include_attributes: false
       ]}
  ]

config :meadow, Meadow.Repo,
  show_sensitive_data_on_connection_error: true,
  timeout: 60_000,
  connect_timeout: 60_000,
  handshake_timeout: 60_000,
  pool: Ecto.Adapters.SQL.Sandbox,
  queue_target: 5000,
  pool_size: 50

if System.get_env("AWS_DEV_ENVIRONMENT") |> is_nil() do
  [:mediaconvert, :s3, :secretsmanager, :sns, :sqs]
  |> Enum.each(fn service ->
    config :ex_aws, service,
      scheme: "http://",
      host: "localhost.localstack.cloud",
      port: 4568,
      access_key_id: "fake",
      secret_access_key: "fake",
      region: "us-east-1"
  end)
end

config :exldap, :settings, base: "OU=test,DC=library,DC=northwestern,DC=edu"

# Print only warnings and errors during test
config :logger, level: :info

config :ex_unit,
  assert_receive_timeout: 500

config :honeybadger,
  environment_name: :test,
  exclude_envs: [:dev, :test],
  api_key: "abc123",
  origin: "http://localhost:4444"

config :meadow, :sitemaps,
  gzip: true,
  store: Sitemapper.S3Store,
  sitemap_url: "http://localhost:3333/",
  store_config: [bucket: "#{prefix}-uploads", path: ""]