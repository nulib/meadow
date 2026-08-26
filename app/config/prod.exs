import Config

# BroadwaySQS only. See the note in config/config.exs. Meadow's own credentials come
# from `aws_credentials`, which walks the standard AWS chain (env, ~/.aws, ECS, EKS,
# web identity, EC2 metadata) with no configuration needed.
config :ex_aws,
  access_key_id: [:instance_role],
  secret_access_key: [:instance_role],
  region: System.get_env("AWS_REGION", "us-east-1")

config :logger,
  compile_time_purge_matching: [
    [level_lower_than: :info]
  ],
  level: :info

config :meadow, :evals,
  default_query_name: "Berkeley Folk Music Festival — has description + subjects"
