defmodule Meadow.Livebook.MixProject do
  use Mix.Project

  @app_version "9.7.5"

  def project do
    [
      app: :meadow_livebook,
      version: @app_version,
      elixir: "~> 1.9",
      elixirc_paths: ["lib"],
      compilers: Mix.compilers(),
      start_permanent: Mix.env() == :prod,
      deps: [{:meadow, path: "/meadow"}]
    ]
  end

  def application do
    []
  end
end
