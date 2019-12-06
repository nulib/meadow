use Mix.Config

# Configure your database
config :meadow, Meadow.Repo,
  username: "docker",
  password: "d0ck3r",
  database: "meadow_test",
  hostname: "localhost",
  port: System.get_env("DB_PORT", "5434"),
  pool: Ecto.Adapters.SQL.Sandbox

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :meadow, MeadowWeb.Endpoint,
  http: [port: 4002],
  server: false

config :meadow,
  ingest_bucket: "test-ingest",
  upload_bucket: "test-uploads",
  preservation_bucket: "test-preservation",
  pyramid_bucket: "test-pyramids"

config :meadow,
  start_pipeline: false

config :ex_aws,
  access_key_id: "minio",
  secret_access_key: "minio123"

config :ex_aws, :s3,
  host: "localhost",
  port: if(System.get_env("CI"), do: 9000, else: 9002),
  scheme: "http://",
  region: "us-east-1",
  http_client: Meadow.ExAwsHttpMock

config :ex_aws, :sqs,
  host: "localhost",
  port: if(System.get_env("CI"), do: 4100, else: 4102),
  scheme: "http://",
  region: "us-east-1"

config :ex_aws, :sns,
  access_key_id: "",
  secret_access_key: "",
  host: "localhost",
  port: if(System.get_env("CI"), do: 4100, else: 4102),
  scheme: "http://",
  region: "us-east-1"

# Print only warnings and errors during test
config :logger, level: :info
