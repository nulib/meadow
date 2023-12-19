import Config
Meadow.Runtime.configure!()

["config/#{config_env()}.exs", "config/#{config_env()}.local.exs"]
|> Enum.each(fn local_file ->
  if File.exists?(local_file), do: Code.require_file(local_file)
end)
