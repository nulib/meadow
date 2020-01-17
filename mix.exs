defmodule Meadow.MixProject do
  use Mix.Project

  def project do
    [
      app: :meadow,
      version: "0.1.0",
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
      extra_applications: [
        :honeybadger,
        :logger,
        :runtime_tools,
        :sequins,
        :ueberauth_openam
      ]
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
      {:absinthe, "~> 1.4.2"},
      {:absinthe_plug, "~> 1.4.0"},
      {:absinthe_phoenix, "~> 1.4.0"},
      {:assertions, "~> 0.15.0", only: :test},
      {:briefly, "~> 0.3.0", only: :test},
      {:bypass, "~> 1.0", only: :test},
      {:con_cache, "~> 0.14.0"},
      {:configparser_ex, "~> 4.0.0"},
      {:credo, "~> 1.2.0", only: [:dev, :test], runtime: false},
      {:dataloader, "~> 1.0.6"},
      {:ecto_ranked, "~> 0.5.0"},
      {:ecto_sql, "~> 3.0"},
      {:ecto_ulid, "~> 0.2.0"},
      {:elasticsearch, "~> 1.0.0"},
      {:ets, "~> 0.8.0"},
      {:ex_aws, "~> 2.1"},
      {:ex_aws_s3, "~> 2.0"},
      {:excoveralls, "~> 0.10", only: :test},
      {:exldap, "~> 0.6.3"},
      {:faker, "~> 0.12", only: [:dev, :test]},
      {:gettext, "~> 0.11"},
      {:hackney, "~> 1.15"},
      {:honeybadger, "~> 0.7"},
      {:inflex, "~> 2.0.0"},
      {:jason, "~> 1.0"},
      {:mox, "~> 0.5", only: :test},
      {:nimble_csv, "~> 0.7.0"},
      {:phoenix, "~> 1.4.10"},
      {:phoenix_html, "~> 2.13"},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:phoenix_pubsub, "~> 1.1"},
      {:phoenix_ecto, "~> 4.0"},
      {:plug_cowboy, "~> 2.0"},
      {:poison, "~> 4.0"},
      {:postgrex, ">= 0.0.0"},
      {:sequins, sequins_version()},
      {:sigaws, "~> 0.7.2"},
      {:sweet_xml, "~> 0.6"},
      {:ueberauth, "~> 0.2"},
      {:ueberauth_openam, "~> 0.2.0"},
      {:wormwood, "~> 0.1.0"}
    ]
  end

  defp sequins_version do
    case System.get_env("SEQUINS", nil) do
      nil -> "~> 0.5.0"
      path -> [path: path]
    end
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to create, migrate and run the seeds file at once:
  #
  #     $ mix ecto.setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: [
        "meadow.pipeline.setup",
        "meadow.ldap.teardown test/fixtures/ldap_seed.ldif",
        "meadow.ldap.setup test/fixtures/ldap_seed.ldif",
        "ecto.create --quiet",
        "ecto.migrate",
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
          observer: :permanent,
          runtime_tools: :permanent
        ],
        steps: [&build_assets/1, :assemble, :tar]
      ]
    ]
  end

  def build_assets(release) do
    System.cmd("yarn", ["deploy"], cd: "assets")
    Mix.Tasks.Phx.Digest.run([])
    release
  end
end
