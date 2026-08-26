import Config

# BroadwaySQS only. See the note in config/config.exs. Meadow's own credentials come
# from `aws_credentials`, which walks the standard AWS chain (env, ~/.aws, ECS, EKS,
# web identity, EC2 metadata) with no configuration needed.
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

  # Point Meadow's own AWS calls (`Meadow.AWS`) at Localstack, for the services Localstack
  # actually provides. Anything not listed here — Bedrock, CloudFront — still resolves to
  # the real AWS endpoint, as it did under ExAws.
  config :meadow, :aws,
    services:
      Map.new(
        [:logs, :mediaconvert, :s3, :secretsmanager, :sns, :sqs],
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

config :meadow, :evals, default_query_name: "match_all"
