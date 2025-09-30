import Config

# Remove environment variables that will mess with the tests
~w(MEADOW_TENANT SECRETS_PATH DEV_PREFIX)
|> Enum.each(&System.delete_env(&1))

config :ex_aws,
  access_key_id: "fake",
  secret_access_key: "fake",
  region: "us-east-1"

IO.puts("Using localstack services for tests")

[:mediaconvert, :s3, :secretsmanager, :sns, :sqs]
|> Enum.each(fn service ->
  config :ex_aws, service,
    scheme: "https://",
    host: "localhost.localstack.cloud",
    port: 4566
end)

# Print only warnings and errors during test
config :logger, level: :info
config :logger, :console, format: {Meadow.TestLogHandler, :format}

config :elixir, :ansi_enabled, true
