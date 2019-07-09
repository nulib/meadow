use Mix.Config

# Configure your database
config :meadow, Meadow.Repo,
  username: "postgres",
  password: "postgres",
  database: "meadow_test",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :meadow, MeadowWeb.Endpoint,
  http: [port: 4002],
  server: false

config :meadow, ingest_bucket: "test-ingest"

config :ex_aws, :s3,
  access_key_id: "minio",
  secret_access_key: "minio123",
  host: "localhost",
  port: if(System.get_env("CI"), do: 9000, else: 9002),
  scheme: "http://",
  region: "us-east-1",
  http_client: Meadow.ExAwsHttpMock

# Print only warnings and errors during test
config :logger, level: :warn
