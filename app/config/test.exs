import Config

# Remove environment variables that will mess with the tests
~w(MEADOW_TENANT SECRETS_PATH DEV_PREFIX)
|> Enum.each(&System.delete_env(&1))

IO.puts("Using localstack services for tests")

# Point Meadow's own AWS calls (`Meadow.AWS`) at Localstack, for the services Localstack
# actually provides. Anything not listed here — Bedrock, CloudFront — still resolves to
# the real AWS endpoint, as it did under ExAws.
config :meadow, :aws,
  services:
    Map.new(
      [:lambda, :logs, :mediaconvert, :s3, :secretsmanager, :sns, :sqs],
      &{&1, [proto: "https", endpoint: "localhost.localstack.cloud", port: 4566]}
    )

# Charlists, not binaries: aws_credentials' env provider runs the value through
# :erlang.list_to_binary/1, which rejects an Elixir binary.
config :aws_credentials,
  credential_providers: [:aws_credentials_env],
  aws_access_key_id: ~c"fake",
  aws_secret_access_key: ~c"fake",
  aws_default_region: ~c"us-east-1"

# BroadwaySQS only. See the note in config/config.exs.
config :ex_aws,
  access_key_id: "fake",
  secret_access_key: "fake",
  region: "us-east-1"

config :ex_aws, :sqs,
  scheme: "https://",
  host: "localhost.localstack.cloud",
  port: 4566

# Print only warnings and errors during test
config :logger, level: :info
config :logger, :console, format: {Meadow.TestLogHandler, :format}

config :elixir, :ansi_enabled, true

config :meadow, :evals, default_query_name: "match_all"
