import Config

if function_exported?(:Hush, :release_mode?, 0) and Hush.release_mode?(),
  do: import_config "releases.exs"

config :logger, level: :debug
config :meadow, MeadowWeb.Endpoint, https: false
