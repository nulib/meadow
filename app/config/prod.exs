import Config

config :ex_aws,
  access_key_id: [:instance_role],
  secret_access_key: [:instance_role],
  region: System.get_env("AWS_REGION", "us-east-1")

config :logger,
  level: :warning
