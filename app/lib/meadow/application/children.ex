defmodule Meadow.Application.Children do
  @moduledoc """
  Child specs for Meadow.Application
  """
  alias Meadow.Application.Caches
  alias Meadow.Config
  alias Meadow.Data.IndexBatcher
  alias Meadow.Data.Schemas.{Collection, FileSet, Work}
  require Logger

  defp basic_processes do
    %{
      "batch_driver" => Meadow.BatchDriver,
      "batchers" =>
        [Work, Collection, FileSet]
        |> Enum.map(&IndexBatcher.child_spec(&1)),
      "csv_update_driver" => Meadow.CSVMetadataUpdateDriver,
      "database_listeners" => [
        {WalEx.Supervisor, Application.get_env(:meadow, WalEx)},
        {Meadow.Events.Works.Arks.Processor,
         token_count: 100, interval: 1_000, replenish_count: 10}
        |> distributed()
      ],
      "scheduler" => Meadow.Scheduler |> distributed(),
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
        {Absinthe.Subscription, MeadowWeb.Endpoint},
        MeadowWeb.Subscription,
        MeadowWeb.MCP.GlobalRegistry,
        {MeadowWeb.MCP.Server,
         transport: :streamable_http, registry: MeadowWeb.MCP.GlobalRegistry}
        |> distributed()
      ],
      "web.notifiers" => [
        {Meadow.Ingest.Progress, interval: Config.progress_ping_interval()}
      ]
    }
  end

  defp agent_processes do
    %{
      "metadata" => {MeadowAI.MetadataAgent, []}
    }
  end

  defp all_processes,
    do:
      basic_processes()
      |> Map.merge(pipeline_processes())
      |> Map.merge(web_processes())
      |> Map.merge(agent_processes())

  defp process_aliases do
    %{
      "all" => all_processes() |> Enum.map(fn {key, _} -> key end),
      "none" => [],
      "basic" => basic_processes() |> Enum.map(fn {key, _} -> key end),
      "pipeline" => pipeline_processes() |> Enum.map(fn {key, _} -> key end),
      "web" => web_processes() |> Enum.map(fn {key, _} -> key end),
      "agent" => agent_processes() |> Enum.map(fn {key, _} -> key end)
    }
  end

  @doc """
  Produce a list of child specs to start under the main supervisor based
  on the current environment
  """
  def specs do
    with env <- Config.environment() do
      [
        Meadow.Notification
        | (Caches.specs(env) ++ specs(env))
          |> Enum.reject(&is_nil/1)
      ]
    end
  end

  defp specs(:dev) do
    [finch_spec(), mock_server(Meadow.Ark.MockServer, 3943)] ++ workers(Config.workers())
  end

  defp specs(:test) do
    [finch_spec(), mock_server(Meadow.Ark.MockServer, 3944), mock_server(Meadow.Directory.MockServer, 3946)] ++
      workers(["web.server"])
  end

  defp specs(:prod) do
    [finch_spec() | workers(Config.workers())]
  end

  defp finch_spec do
    multipart_processors =
      Application.get_env(:meadow, Meadow.Pipeline)
      |> get_in([
        Meadow.Pipeline.Actions.CopyFileToPreservation,
        :processors,
        :default,
        :concurrency
      ])

    multipart_concurrency = Application.get_env(:meadow, :multipart_upload_concurrency)
    pool_size = multipart_processors * multipart_concurrency + 500

    Logger.info("Starting Finch pool with #{pool_size} connections")

    {
      Finch,
      [
        name: Meadow.FinchPool,
        pools: %{
          default: [size: pool_size]
        }
      ]
    }
  end

  def processes("aliases"), do: process_aliases()
  def processes("all"), do: all_processes()
  def processes("basic"), do: basic_processes()
  def processes("pipeline"), do: pipeline_processes()
  def processes("web"), do: web_processes()
  def processes("agent"), do: agent_processes()

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

  defp mock_server(plug, port) do
    case :gen_tcp.connect(~c"localhost", port, [], 500) do
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

  def distributed(%{start: {mod, fun, [args]}} = spec) do
    %{spec | start: {mod, fun, [via_horde(Keyword.put_new(args, :name, mod))]}}
  end

  def distributed(%{start: {mod, fun, args}} = spec) do
    %{spec | start: {mod, fun, via_horde(Keyword.put_new(args, :name, mod))}}
  end

  def distributed({mod, args}) do
    {mod, via_horde(Keyword.put_new(args, :name, mod))}
  end

  def distributed(mod), do: {mod, via_horde(name: mod)}

  defp via_horde(args) do
    Keyword.update(args, :name, nil, fn name ->
      if is_atom(name),
        do: {:via, Horde.Registry, {Meadow.HordeRegistry, name}},
        else: name
    end)
  end
end
