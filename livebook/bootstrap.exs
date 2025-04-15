Path.wildcard("/meadow/lib/*/ebin")
|> Enum.each(&:code.add_path(String.to_charlist(&1)))

defmodule Meadow.Bootstrap do
  require Logger

  def bootstrap do
    case Application.started_applications() |> Enum.find(fn {app, _, _} -> app == :meadow end) do
      nil ->
        load_meadow()

      {app, _, _} ->
        Logger.warning("Meadow is already loaded: #{inspect(app)}")
        :ok
    end
  end

  defp load_meadow do
    set_environment()
    Application.ensure_all_started(:mix)

    with config <- Config.Reader.read!("/meadow/config/config.exs") do
      Enum.map(config, fn {app, _} ->
        {app, Application.get_all_env(app)}
      end)
      |> Config.Reader.merge(config)
      |> Application.put_all_env()
    end

    Application.load(:meadow)
    if :code.is_loaded(Mix), do: Meadow.Config.Runtime.configure!()
    Logger.configure(level: :info)
    Application.ensure_all_started(:meadow)
  end

  defp set_environment do
    unless System.get_env("MEADOW_PROCESSES") do
      System.put_env("MEADOW_PROCESSES", "batchers")
    end

    unless System.get_env("SECRETS_PATH") do
      raise "SECRETS_PATH must be set to a valid configuration path"
    end
  end
end
