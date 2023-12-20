import Config
Meadow.Runtime.configure!()

local_file = "config/#{config_env()}.local.exs"
if File.exists?(local_file), do: Code.require_file(local_file)
