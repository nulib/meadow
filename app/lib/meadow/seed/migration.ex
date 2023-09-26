defmodule Meadow.Seed.Migration do
  @moduledoc """
  Functions to help make sure the seed import runs against the
  correct version of the schema
  """
  alias Meadow.Repo

  require Logger

  def latest_version do
    Ecto.Migrator.migrations(Repo)
    |> Enum.reverse()
    |> Enum.find_value(fn
      {:up, version, _} -> version
      _ -> nil
    end)
  end

  def target_version(target) do
    Ecto.Migrator.migrations(Repo)
    |> Enum.filter(fn {status, _, _} -> status == :up end)
    |> Enum.reverse()
    |> Enum.reduce(nil, fn
      {:up, version, _}, nil -> version
      {:up, version, _}, acc -> if version > target, do: version, else: acc
    end)
  end

  def with_database_version(version, func) do
    if version < latest_version() do
      target_version = target_version(version)
      Logger.warning("Migrating Repo down to #{version}")
      Ecto.Migrator.run(Repo, :down, to: target_version)
      func.()
      :timer.sleep(2000)
      Logger.warning("Migrating Repo up to current")
      Ecto.Migrator.run(Repo, :up, all: true)
    else
      func.()
    end
  end
end
