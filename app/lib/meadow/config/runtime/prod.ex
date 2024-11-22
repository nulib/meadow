defmodule Meadow.Config.Runtime.Prod do
  @moduledoc """
  Load and apply Meadow's runtime configuration for the production environment
  """

  def configure! do
    import Config

    config :meadow, MeadowWeb.Endpoint,
      environment: :prod,
      environment_prefix: nil,
      url: [host: System.get_env("MEADOW_HOSTNAME", "example.com"), port: 80],
      cache_static_manifest: "priv/static/cache_manifest.json",
      server: true
  end
end
