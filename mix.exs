defmodule Meadow.MixProject do
  use Mix.Project

  @app_version "5.1.3"

  def project do
    [
      app: :meadow,
      version: @app_version,
      elixir: "~> 1.9",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: [:phoenix, :gettext] ++ Mix.compilers(),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.circle": :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ],
      releases: releases()
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {Meadow.Application, []},
      extra_applications: [:os_mon, :retry]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:absinthe, "~> 1.7.0"},
      {:absinthe_plug, "~> 1.5.0"},
      {:absinthe_phoenix, "~> 2.0.0"},
      {:assertions, "~> 0.19.0", only: :test},
      {:authoritex, "~> 0.9.0"},
      {:briefly, "~> 0.3.0", only: :test},
      {:cachex, "~> 3.2"},
      {:configparser_ex, "~> 4.0.0"},
      {:credo, "~> 1.6.1", only: [:dev, :test], runtime: false},
      {:dataloader, "~> 1.0.6"},
      {:ecto_enum, "~> 1.4.0"},
      {:ecto_psql_extras, "~> 0.2"},
      {:ecto_ranked, "~> 0.5.0"},
      {:ecto_sql, "~> 3.0 and >= 3.4.4"},
      {:elastix, "~> 0.10.0"},
      {:elasticsearch, "~> 1.0.0"},
      {:ets, "~> 0.8.0"},
      {:ex_aws, "~> 2.2.0"},
      {:ex_aws_s3,
       git: "https://github.com/bmquinn/ex_aws_s3.git", branch: "main", override: true},
      {:ex_aws_lambda, "~> 2.0"},
      {:excoveralls, "~> 0.10", only: :test},
      {:exldap, "~> 0.6.3"},
      {:faker, "~> 0.12", only: [:dev, :test]},
      {:gettext, "~> 0.11"},
      {:hackney, "~> 1.17"},
      {:honeybadger, "~> 0.7"},
      {:inflex, "~> 2.1.0"},
      {:jason, "~> 1.0"},
      {:logger_file_backend, "~> 0.0.11"},
      {:mox, "~> 1.0", only: :test},
      {:nimble_csv, "~> 1.1.0"},
      {:phoenix, "~> 1.6.0"},
      {:phoenix_html, "~> 3.0"},
      {:phoenix_live_view, "~> 0.16.4"},
      {:phoenix_live_dashboard, "~> 0.5"},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:phoenix_pubsub, "~> 2.0"},
      {:phoenix_ecto, "~> 4.1"},
      {:plug_cowboy, "~> 2.0"},
      {:poison, "~> 4.0"},
      {:postgrex, ">= 0.0.0"},
      {:quantum, "~> 3.0"},
      {:retry, "~> 0.15.0"},
      {:sequins, "~> 0.8.0"},
      {:sigaws, git: "https://github.com/nulib/sigaws.git", branch: "otp-24", override: true},
      {:sitemapper, "~> 0.6.0"},
      {:sweet_xml, "~> 0.6"},
      {:telemetry_metrics, "~> 0.6"},
      {:telemetry_poller, "~> 0.5"},
      {:tzdata, "~> 1.1.0"},
      {:ueberauth_nusso, "~> 0.2.4"},
      {:wait_for_it, "~> 1.3.0"},
      {:wormwood, "~> 0.1.0"}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to create, migrate and run the seeds file at once:
  #
  #     $ mix ecto.setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      "ecto.setup": ["ecto.create --quiet", "ecto.migrate", "meadow.seed"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      "meadow.setup": [
        "assets.install",
        "meadow.pipeline.setup",
        "meadow.buckets.create",
        "ecto.setup",
        "meadow.elasticsearch.setup"
      ],
      test: [
        "meadow.pipeline.setup",
        "meadow.buckets.create",
        "meadow.ldap.teardown test/fixtures/ldap_seed.ldif",
        "meadow.ldap.setup test/fixtures/ldap_seed.ldif",
        "ecto.setup",
        "test"
      ]
    ]
  end

  defp releases do
    [
      meadow: [
        include_executables_for: [:unix],
        applications: [
          meadow: :permanent,
          runtime_tools: :permanent
        ],
        extra_applications: [:os_mon],
        steps: [&build_assets/1, :assemble]
      ]
    ]
  end

  def build_assets(release) do
    System.cmd("npm", ["run-script", "deploy"], cd: "assets")
    Mix.Task.run("phx.digest")
    release
  end
end
