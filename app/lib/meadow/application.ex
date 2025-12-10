defmodule Meadow.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application
  use Retry
  alias Meadow.Application.Children
  alias Meadow.Config.Runtime

  require Logger
  require WaitForIt

  def start(_type, _args) do
    result =
      Supervisor.start_link(
        [
          {DynamicSupervisor,
           max_restarts: 4096, strategy: :one_for_one, name: Meadow.Supervisor},
          {Horde.Registry, name: Meadow.HordeRegistry, keys: :unique, members: :auto},
          {Horde.DynamicSupervisor,
           name: Meadow.HordeSupervisor,
           distribution_strategy: Horde.UniformDistribution,
           strategy: :one_for_one,
           members: :auto}
        ],
        max_restarts: 4096,
        strategy: :one_for_one,
        name: Meadow.TopSupervisor
      )

    Logger.info("Starting Meadow application")

    unless :code.is_loaded(Mix) do
      Runtime.configure!()
    end

    if System.get_env("CLUSTER_ENABLED") == "true" do
      Logger.info("Starting libcluster")
      topologies = Application.get_env(:libcluster, :topologies, [])

      DynamicSupervisor.start_child(
        Meadow.Supervisor,
        {Cluster.Supervisor, [topologies, [name: Meadow.ClusterSupervisor]]}
      )

      Logger.info("Waiting for cluster")

      WaitForIt.case_wait Horde.Cluster.members(Meadow.HordeSupervisor),
        timeout: :timer.seconds(10),
        interval: :timer.seconds(1) do
        nodes when length(nodes) > 1 ->
          Logger.info("Cluster formed with nodes: #{inspect(nodes)}")
      else
        Logger.warning("Timeout waiting for cluster formation. Continuing with single node.")
      end

      Logger.info("Waiting for quorum")
      Horde.DynamicSupervisor.wait_for_quorum(Meadow.HordeSupervisor, :timer.seconds(10))
    end

    Logger.info("Starting Anubis MCP server")
    Application.ensure_all_started(:anubis_mcp)

    unless System.get_env("MEADOW_NO_REPO") do
      DynamicSupervisor.start_child(Meadow.Supervisor, Meadow.Repo)
      DynamicSupervisor.start_child(Meadow.Supervisor, Meadow.Repo.Indexing)
      Meadow.Repo.wait_for_connection()
    end

    start_children()

    :telemetry.attach(
      "reorder-file-sets-stop-handler",
      [:meadow, :data, :works, :reorder_file_sets, :stop],
      &Meadow.Telemetry.handle_reorder_file_sets_stop_event/4,
      nil
    )

    result
  end

  def children do
    [
      {Phoenix.PubSub, [name: Meadow.PubSub, adapter: Phoenix.PubSub.PG2]},
      Meadow.Telemetry,
      {Registry, keys: :unique, name: Meadow.TaskRegistry}
    ] ++ Children.specs()
  end

  def start_children() do
    children()
    |> start_children()
  end

  def start_children(children) do
    retry with: exponential_backoff() |> randomize() |> cap(10_000) |> Stream.take(10) do
      children
      |> Enum.each(fn spec ->
        if distributed?(spec) do
          Horde.DynamicSupervisor.start_child(Meadow.HordeSupervisor, spec)
        else
          DynamicSupervisor.start_child(Meadow.Supervisor, spec)
        end
        |> case do
          {:ok, _pid} ->
            :ok

          {:error, {:already_started, _pid}} ->
            Logger.warning("Not starting #{inspect(spec)}: already started")
            :ok

          {:error, reason} ->
            Logger.error("Failed to start child #{inspect(spec)}: #{inspect(reason)}")
        end
      end)
    end
  end

  def start_distributed do
    children()
    |> Enum.filter(&distributed?/1)
    |> start_children()
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    MeadowWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  defp spec_name(child_spec) do
    case child_spec do
      %{start: {_mod, _fun, [args]}} when is_list(args) -> Keyword.get(args, :name)
      %{start: {_mod, _fun, args}} when is_list(args) -> Keyword.get(args, :name)
      {_mod, opts} when is_list(opts) -> Keyword.get(opts, :name)
      %{id: {:via, Horde.Registry, _} = name} -> name
      _ -> nil
    end
  end

  defp distributed?(child_spec), do: spec_name(child_spec) |> via_horde?()

  defp via_horde?({:via, Horde.Registry, _}), do: true
  defp via_horde?(_), do: false
end
