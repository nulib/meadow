defmodule Meadow.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application
  alias Meadow.Application.Children

  require Logger

  def start(_type, _args) do
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
      {Phoenix.PubSub, [name: Meadow.PubSub, adapter: Phoenix.PubSub.PG2]},
      Meadow.Telemetry,
      {Registry, keys: :unique, name: Meadow.TaskRegistry}
    ]

    children = base_children ++ Children.specs()

    children
    |> Enum.each(&DynamicSupervisor.start_child(Meadow.Supervisor, &1))

    :telemetry.attach(
      "reorder-file-sets-stop-handler",
      [:meadow, :data, :works, :reorder_file_sets, :stop],
      &Meadow.Telemetry.handle_reorder_file_sets_stop_event/4,
      nil
    )

    result
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    MeadowWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
