# Do not use this file! Use lib/meadow/runtime/test.ex instead.

import Config

if System.get_env("AWS_DEV_ENVIRONMENT") |> is_nil() do
  [:mediaconvert, :s3, :secretsmanager, :sns, :sqs]
  |> Enum.each(fn service ->
    config :ex_aws, service,
      scheme: "http://",
      host: "localhost.localstack.cloud",
      port: 4566,
      access_key_id: "fake",
      secret_access_key: "fake",
      region: "us-east-1"
  end)
end
