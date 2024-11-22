import Config

config :ex_aws,
  access_key_id: "fake",
  secret_access_key: "fake",
  region: "us-east-1"

if System.get_env("AWS_DEV_ENVIRONMENT") |> is_nil() do
  [:mediaconvert, :s3, :secretsmanager, :sns, :sqs]
  |> Enum.each(fn service ->
    config :ex_aws, service,
      scheme: "http://",
      host: "localhost.localstack.cloud",
      port: 4566
  end)
end

# Print only warnings and errors during test
config :logger, level: :info
config :logger, :console, format: {Meadow.TestLogHandler, :format}

config :elixir, :ansi_enabled, true
