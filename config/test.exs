import Config

# Configure your database
config :meadow, Meadow.Repo,
  username: "docker",
  password: "d0ck3r",
  database: "meadow_test",
  hostname: "localhost",
  port: System.get_env("DB_PORT", "5434"),
  pool: Ecto.Adapters.SQL.Sandbox,
  queue_target: 5000,
  pool_size: 50

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :meadow, MeadowWeb.Endpoint,
  http: [port: 4002],
  server: false

config :meadow, Meadow.ElasticsearchCluster,
  url: System.get_env("ELASTICSEARCH_URL", "http://localhost:9202"),
  indexes: %{
    meadow: %{
      settings: "priv/elasticsearch/meadow.json",
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
  ingest_bucket: "test-ingest",
  upload_bucket: "test-uploads",
  preservation_bucket: "test-preservation",
  preservation_check_bucket: "test-preservation-checks",
  pyramid_bucket: "test-pyramids",
  streaming_bucket: "test-streaming",
  streaming_url: "https://test-streaming-url/",
  mediaconvert_client: MediaConvert.Mock,
  iiif_server_url: "http://localhost:8184/iiif/2/",
  iiif_manifest_url: "http://localhost:9002/minio/test-pyramids/public/",
  digital_collections_url: "https://fen.rdc-staging.library.northwestern.edu/",
  work_archiver_endpoint: ""

config :meadow,
  checksum_notification: %{
    arn: "arn:minio:sqs::checksum:webhook",
    buckets: ["test-ingest", "test-uploads"]
  },
  required_checksum_tags: ["computed-md5"],
  checksum_wait_timeout: 5_000

config :meadow,
  ark: %{
    default_shoulder: "ark:/12345/nu2",
    user: "mockuser",
    password: "mockpassword",
    target_url: "https://devbox.library.northwestern.edu:3333/items/",
    url: "http://localhost:3944/"
  }

config :authoritex, authorities: [Authoritex.Mock, NUL.Authority]

config :ueberauth, Ueberauth,
  providers: [
    nusso:
      {Ueberauth.Strategy.NuSSO,
       [
         base_url: "https://northwestern-dev.apigee.net/agentless-websso/",
         callback_path: "/auth/nusso/callback",
         consumer_key: "test-sso-key",
         include_attributes: true
       ]}
  ]

config :ex_aws,
  access_key_id: "minio",
  secret_access_key: "minio123"

config :ex_aws, :s3,
  host: "localhost",
  port: 9002,
  scheme: "http://",
  region: "us-east-1",
  access_key_id: "minio",
  secret_access_key: "minio123"

config :ex_aws, :sqs,
  host: "localhost",
  port: 4102,
  scheme: "http://",
  region: "us-east-1"

config :ex_aws, :sns,
  access_key_id: "",
  secret_access_key: "",
  host: "localhost",
  port: 4102,
  scheme: "http://",
  region: "us-east-1"

config :exldap, :settings,
  server: "localhost",
  base: "DC=library,DC=northwestern,DC=edu",
  port: 391,
  user_dn: "cn=Administrator,cn=Users,dc=library,dc=northwestern,dc=edu",
  password: "d0ck3rAdm1n!"

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
  store_config: [bucket: "test-uploads"]
