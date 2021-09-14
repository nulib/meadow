import Config

get_required_var = fn var ->
  System.get_env(var) || raise "environment variable #{var} is missing."
end

# Configure your database
config :meadow, Meadow.Repo,
  # ssl: true,
  url: get_required_var.("DATABASE_URL"),
  pool_size: String.to_integer(System.get_env("POOL_SIZE", "10")),
  queue_target: String.to_integer(System.get_env("DB_QUEUE_TARGET", "50")),
  queue_interval: String.to_integer(System.get_env("DB_QUEUE_INTERVAL", "1000"))

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
    recv_timeout: 30_000
  ],
  json_library: Jason,
  indexes: %{
    meadow: %{
      settings: "priv/elasticsearch/meadow.json",
      store: Meadow.ElasticsearchStore,
      sources: [Meadow.Data.Schemas.Work, Meadow.Data.Schemas.Collection],
      bulk_page_size: 200,
      bulk_wait_interval: 500
    }
  }

config :meadow,
  ark: %{
    default_shoulder: get_required_var.("EZID_SHOULDER"),
    user: get_required_var.("EZID_USER"),
    password: get_required_var.("EZID_PASSWORD"),
    target_url: get_required_var.("EZID_TARGET_BASE_URL")
  }

config :meadow, pipeline_delay: :timer.seconds(5)
config :meadow, environment: :prod
config :meadow, ingest_bucket: get_required_var.("INGEST_BUCKET")
config :meadow, preservation_bucket: get_required_var.("PRESERVATION_BUCKET")
config :meadow, upload_bucket: get_required_var.("UPLOAD_BUCKET")
config :meadow, pyramid_bucket: get_required_var.("PYRAMID_BUCKET")
config :meadow, preservation_check_bucket: get_required_var.("PRESERVATION_CHECK_BUCKET")
config :meadow, iiif_server_url: get_required_var.("IIIF_SERVER_URL")
config :meadow, iiif_manifest_url: get_required_var.("IIIF_MANIFEST_URL")
config :meadow, digital_collections_url: get_required_var.("DIGITAL_COLLECTIONS_URL")
config :meadow, mediaconvert_client: MediaConvert,
config :meadow, mediaconvert_queue: get_required_var.("MEDIACONVERT_QUEUE")
config :meadow, mediaconvert_role: get_required_var.("MEDIACONVERT_ROLE")
config :meadow, streaming_bucket: get_required_var.("STREAMING_BUCKET")
config :meadow, sitemaps: [
  gzip: true,
  store: Sitemapper.S3Store,
  store_config: [bucket: get_required_var.("SITEMAP_BUCKET")],
  sitemap_url: get_required_var.("DIGITAL_COLLECTIONS_URL")
]

config :elastix,
  custom_headers:
    {Meadow.Utils.AWS, :add_aws_signature,
     [
       get_required_var.("AWS_REGION"),
       get_required_var.("ELASTICSEARCH_KEY"),
       get_required_var.("ELASTICSEARCH_SECRET")
     ]}

config :sequins,
  prefix: "meadow",
  supervisor_opts: [max_restarts: 2048]

config :exldap, :settings,
  server: System.get_env("LDAP_SERVER", "localhost"),
  base: System.get_env("LDAP_BASE_DN", "DC=library,DC=northwestern,DC=edu"),
  port: String.to_integer(System.get_env("LDAP_PORT", "390")),
  user_dn:
    System.get_env("LDAP_BIND_DN", "cn=Administrator,cn=Users,dc=library,dc=northwestern,dc=edu"),
  password: System.get_env("LDAP_BIND_PASSWORD", "d0ck3rAdm1n!"),
  ssl: System.get_env("LDAP_SSL", "false") == "true"

config :logger,
  backends: [
    :console,
    {LoggerFileBackend, :cloudwatch}
  ]

config :logger, :console,
  format: "$metadata[$level] $levelpad$message\n",
  metadata: [:action]

config :logger, :cloudwatch,
  path: "/var/log/meadow/meadow.log",
  format: "$date $time [$level] $metadata $levelpad$message\n",
  metadata: [:action],
  level: :info,
  colors: [enabled: false]

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

config :hackney, max_connections: 1_000
config :ex_aws, hackney_opts: [recv_timeout: 120_000]

config :meadow, :lambda,
  digester: {:lambda, "meadow-digester"},
  "pyramid-tiff": {:lambda, "meadow-pyramid-tiff"}

config :sequins, Actions.GenerateFileSetDigests,
  queue_config: [processor_concurrency: 50, visibility_timeout: 300]

config :sequins, Actions.CreatePyramidTiff,
  queue_config: [processor_concurrency: 50, visibility_timeout: 600]
