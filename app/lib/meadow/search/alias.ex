defmodule Meadow.Search.Alias do
  @moduledoc """
  Meadow config-aware wrapper for Elastix.Alias
  """
  alias Elastix.Alias, as: ElastixAlias
  alias Meadow.Error
  alias Meadow.Search.Config, as: SearchConfig

  @doc """
  Add an alias to an index
  """
  def add(alias, index) do
    ElastixAlias.post(
      SearchConfig.cluster_url(),
      [add_action(alias, index)]
    )
  end

  @doc """
  Remove an alias from an index
  """
  def remove(alias, indexes) do
    ElastixAlias.post(
      SearchConfig.cluster_url(),
      Enum.map(indexes, &remove_action(alias, &1))
    )
  end

  @doc """
  List the current index targets for a given alias
  """
  def get_targets(alias) do
    case ElastixAlias.get(SearchConfig.cluster_url(), alias) do
      {:ok, %{body: body, status_code: 200}} ->
        {:ok, Map.keys(body)}

      {:ok, %{status_code: 404}} ->
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

    ElastixAlias.post(SearchConfig.cluster_url(), actions)
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
