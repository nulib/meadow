defmodule Meadow.Application.Children do
  @moduledoc """
  Child specs for Meadow.Application
  """
  alias Meadow.Application.Caches
  alias Meadow.Config
  alias Meadow.Utils.ArkClient
  require Logger

  def specs do
    (Caches.specs(Config.environment()) ++
       specs(Config.environment()))
    |> Enum.reject(&is_nil/1)
  end

  defp specs(:dev) do
    [
      {Meadow.Data.IndexWorker, interval: Config.index_interval()},
      Meadow.IIIF.ManifestListener,
      Meadow.Ingest.WorkCreator,
      mock_ark_server(3943)
    ]
  end

  defp specs(:test) do
    [mock_ark_server(3944)]
  end

  defp specs(:prod) do
    [
      {Meadow.Data.IndexWorker, interval: Config.index_interval()},
      Meadow.IIIF.ManifestListener,
      Meadow.Ingest.WorkCreator
    ]
  end

  defp mock_ark_server(port) do
    plug = ArkClient.MockServer

    case :gen_tcp.connect('localhost', port, [], 50) do
      {:ok, _} ->
        "Skipping launch of #{inspect(plug)}. Port #{port} already in use."
        |> Logger.info()

        nil

      {:error, _} ->
        cowboy_version = Application.spec(:cowboy)[:vsn]

        "Running #{inspect(plug)} with cowboy #{cowboy_version} at 0.0.0.0:#{port} (http)"
        |> Logger.info()

        {Plug.Cowboy, scheme: :http, plug: plug, options: [port: port]}
    end
  end
end
