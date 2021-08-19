defmodule Meadow.Application.Children do
  @moduledoc """
  Child specs for Meadow.Application
  """
  alias Meadow.Application.Caches
  alias Meadow.Config
  alias Meadow.Utils.ArkClient
  require Logger

  defp basic_processes do
    %{
      "batch_driver" => Meadow.BatchDriver,
      "csv_update_driver" => Meadow.CSVMetadataUpdateDriver,
      "index_worker" => {Meadow.Data.IndexWorker, interval: Config.index_interval()},
      "database_listeners" => [
        Meadow.FilesetDeleteListener,
        Meadow.IIIF.ManifestListener,
        Meadow.StructuralMetadataListener
      ],
      "scheduler" => Meadow.Scheduler,
      "work_creator" => [Meadow.Ingest.WorkCreator, Meadow.Ingest.WorkRedriver]
    }
  end

  defp pipeline_processes do
    Meadow.Pipeline.children()
    |> Enum.map(fn {action, _} = spec ->
      key =
        "pipeline." <>
          (action |> Module.split() |> List.last() |> Inflex.underscore())

      {key, spec}
    end)
    |> Enum.into(%{})
  end

  defp web_processes do
    %{
      "web.server" => [
        MeadowWeb.Endpoint,
        {Absinthe.Subscription, MeadowWeb.Endpoint}
      ],
      "web.notifiers" => [
        {Meadow.Ingest.Progress, interval: Config.progress_ping_interval()},
        Meadow.Ingest.SheetNotifier
      ]
    }
  end

  defp all_processes,
    do: basic_processes() |> Map.merge(pipeline_processes()) |> Map.merge(web_processes())

  defp process_aliases do
    %{
      "all" => all_processes() |> Enum.map(fn {key, _} -> key end),
      "none" => [],
      "basic" => basic_processes() |> Enum.map(fn {key, _} -> key end),
      "pipeline" => pipeline_processes() |> Enum.map(fn {key, _} -> key end),
      "web" => web_processes() |> Enum.map(fn {key, _} -> key end)
    }
  end

  @doc """
  Produce a list of child specs to start under the main supervisor based
  on the current environment
  """
  def specs do
    with env <- Config.environment() do
      (Caches.specs(env) ++ specs(env))
      |> Enum.reject(&is_nil/1)
    end
  end

  defp specs(:dev) do
    [mock_ark_server(3943) | workers(Config.workers())]
  end

  defp specs(:test) do
    [mock_ark_server(3944) | workers(["web.server"])]
  end

  defp specs(:prod) do
    workers(Config.workers())
  end

  def processes("aliases"), do: process_aliases()
  def processes("all"), do: all_processes()
  def processes("basic"), do: basic_processes()
  def processes("pipeline"), do: pipeline_processes()
  def processes("web"), do: web_processes()
  def processes(_), do: []

  defp expand_workers(workers) do
    workers
    |> Enum.map(fn worker -> Map.get(process_aliases(), worker, worker) end)
    |> List.flatten()
    |> Enum.uniq()
  end

  def workers(workers) do
    workers
    |> expand_workers()
    |> Enum.map(fn worker -> Map.get(all_processes(), worker) end)
    |> Enum.reject(&is_nil/1)
    |> List.flatten()
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
