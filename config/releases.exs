# In this file, we load production configuration and
# secrets from environment variables. You can also
# hardcode secrets, although such is generally not
# recommended and you have to remember to add this
# file to your .gitignore.
import Config

get_required_var = fn var ->
  System.get_env(var) || raise "environment variable #{var} is missing."
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
  # ssl: true,
  url: get_required_var.("DATABASE_URL"),
  pool_size: String.to_integer(System.get_env("POOL_SIZE", "10"))

host = System.get_env("MEADOW_HOSTNAME", "example.com")
port = String.to_integer(System.get_env("PORT", "4000"))

config :meadow, MeadowWeb.Endpoint,
  url: [host: host, port: port],
  http: [:inet6, port: port],
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
    ]
  ],
  json_library: Jason,
  indexes: %{
    meadow: %{
      settings: Meadow.Config.priv_path("elasticsearch/meadow.json"),
      store: Meadow.ElasticsearchStore,
      sources: [Meadow.Data.Schemas.Work, Meadow.Data.Schemas.Collection],
      bulk_page_size: 500,
      bulk_wait_interval: 2_000
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
  pipeline_delay: System.get_env("PIPELINE_DELAY", "120000"),
  preservation_bucket: get_required_var.("PRESERVATION_BUCKET"),
  progress_ping_interval: System.get_env("PROGRESS_PING_INTERVAL", "1000"),
  pyramid_bucket: get_required_var.("PYRAMID_BUCKET"),
  pyramid_tiff_working_dir: System.get_env("PYRAMID_TIFF_WORKING_DIR"),
  upload_bucket: get_required_var.("UPLOAD_BUCKET"),
  validation_ping_interval: System.get_env("VALIDATION_PING_INTERVAL", "1000")

config :honeybadger,
  api_key: get_required_var.("HONEYBADGER_API_KEY"),
  environment_name: :prod,
  exclude_envs: [:dev, :test]

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
