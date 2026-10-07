import Config

config :logger,
  compile_time_purge_matching: [
    [level_lower_than: :info]
  ],
  level: :info

config :meadow, :evals,
  default_query_name: "Berkeley Folk Music Festival — has description + subjects"
