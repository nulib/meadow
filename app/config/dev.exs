import Config

config :ex_aws,
  access_key_id: [:instance_role],
  secret_access_key: [:instance_role],
  region: System.get_env("AWS_REGION", "us-east-1")

if System.get_env("AWS_LOCALSTACK", "false") == "true" do
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
      buckets: ["dev-ingest", "dev-uploads"]
    },
    mediaconvert_client: MediaConvert.Mock

  [:logs, :mediaconvert, :s3, :secretsmanager, :sns, :sqs]
  |> Enum.each(fn service ->
    config :ex_aws, service,
      scheme: "https://",
      host: "localhost.localstack.cloud",
      port: 4566,
      access_key_id: "fake",
      secret_access_key: "fake",
      region: "us-east-1"
  end)
end

config :meadow, MeadowWeb.Endpoint,
  code_reloader: true,
  debug_errors: true

# Do not include metadata nor timestamps in development logs
config :logger, :console,
  format: "$metadata[$level] $message\n",
  metadata: [:module, :id]

# Set a higher stacktrace during development. Avoid configuring such
# in production as building large stacktraces may be expensive.
config :phoenix, :stacktrace_depth, 20

# Initialize plugs at runtime for faster development compilation
config :phoenix, :plug_init_mode, :runtime
