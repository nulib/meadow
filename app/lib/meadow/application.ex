defmodule Meadow.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application
  alias Meadow.Application.Children
  alias Meadow.Utils.Elasticsearch.RetryAPI

  require Logger

  def start(_type, _args) do
    RetryAPI.configure()

    result =
      Supervisor.start_link(
        [
          {DynamicSupervisor, max_restarts: 4096, strategy: :one_for_one, name: Meadow.Supervisor}
        ],
        max_restarts: 4096,
        strategy: :one_for_one,
        name: Meadow.TopSupervisor
      )

    unless System.get_env("MEADOW_NO_REPO") do
      DynamicSupervisor.start_child(Meadow.Supervisor, Meadow.Repo)
      Meadow.Repo.wait_for_connection()
    end

    base_children = [
      EDTF,
      {Phoenix.PubSub, [name: Meadow.PubSub, adapter: Phoenix.PubSub.PG2]},
      Meadow.ElasticsearchCluster,
      Meadow.Telemetry,
      {Registry, keys: :unique, name: Meadow.TaskRegistry}
    ]

    children = base_children ++ Children.specs()

    children
    |> Enum.each(&DynamicSupervisor.start_child(Meadow.Supervisor, &1))

    result
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    MeadowWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end