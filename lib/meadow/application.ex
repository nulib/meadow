defmodule Meadow.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    # List all child processes to be supervised
    children = [
      # Start the Ecto repository
      Meadow.Repo,
      # Start the endpoint when the application starts
      MeadowWeb.Endpoint
      # Starts a worker by calling: Meadow.Worker.start_link(arg)
      # {Meadow.Worker, arg},
    ]

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
