defmodule Meadow.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application
  alias Meadow.Ingest.Pipeline

  def start(_type, _args) do
    import Supervisor.Spec

    # List all child processes to be supervised
    # Start the Ecto repository
    # Start the endpoint when the application starts
    # Starts a worker by calling: Meadow.Worker.start_link(arg)
    # {Meadow.Worker, arg},
    children = [
      Meadow.Repo,
      MeadowWeb.Endpoint,
      supervisor(Absinthe.Subscription, [MeadowWeb.Endpoint]),
      {Registry, keys: :unique, name: Meadow.TaskRegistry}
    ]

    if Meadow.Config.start_pipeline?(), do: Pipeline.start()

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Meadow.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    MeadowWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
