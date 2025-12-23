defmodule Meadow.Config.Runtime.Prod do
  @moduledoc """
  Load and apply Meadow's runtime configuration for the production environment
  """

  def configure! do
    import Meadow.Config.Helper

    config :meadow, MeadowWeb.Endpoint,
      environment: :prod,
      environment_prefix: nil,
      url: [host: System.get_env("MEADOW_HOSTNAME", "example.com"), port: 443],
      cache_static_manifest: "priv/static/cache_manifest.json",
      server: true

    if System.get_env("CLUSTER_ENABLED") == "true" do
      config :libcluster,
        topologies: [
          ecs: [
            strategy: Cluster.Strategy.DNSPoll,
            config: [
              polling_interval: 5_000,
              query: System.get_env("CLUSTER_DNS_NAME"),
              node_basename: Node.self() |> to_string() |> String.split("@") |> hd()
            ]
          ]
        ]
    end
  end
end
