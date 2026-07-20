defmodule Meadow.Search.Alias do
  @moduledoc """
  Meadow config-aware wrapper for OpenSearch alias operations
  """
  alias Meadow.Error
  alias Meadow.Search.HTTP

  @doc """
  Add an alias to an index
  """
  def add(alias, index) do
    HTTP.post("_aliases", json: %{actions: [add_action(alias, index)]})
  end

  @doc """
  Remove an alias from an index
  """
  def remove(alias, indexes) do
    HTTP.post("_aliases", json: %{actions: Enum.map(indexes, &remove_action(alias, &1))})
  end

  @doc """
  List the current index targets for a given alias
  """
  def get_targets(alias) do
    case HTTP.get("_alias/#{alias}") do
      {:ok, %{body: body, status: 200}} ->
        {:ok, Map.keys(body)}

      {:ok, %{status: 404}} ->
        {:ok, []}

      {:ok, %{body: %{error: error}}} ->
        Error.log_and_report(
          "Problem getting targets for #{alias}",
          error,
          __MODULE__,
          [],
          %{}
        )

        {:error, error}
    end
  end

  @doc """
  Remove an alias from a list of old targets and add it to a new target
  """
  def swap(alias, new_target, old_targets) do
    actions = [
      add_action(alias, new_target)
      | Enum.map(old_targets, &remove_action(alias, &1))
    ]

    HTTP.post("_aliases", json: %{actions: actions})
  end

  @doc """
  Ensure that an alias points only to the given index
  """
  def update(alias, index) do
    with {:ok, old_targets} <- get_targets(alias) do
      swap(alias, index, old_targets |> Enum.filter(&(&1 != index)))
    end
  end

  defp add_action(alias, index), do: %{add: %{index: index, alias: alias}}
  defp remove_action(alias, index), do: %{remove: %{index: index, alias: alias}}
end
