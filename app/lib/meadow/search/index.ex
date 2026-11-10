defmodule Meadow.Search.Index do
  @moduledoc """
  Meadow config-aware wrapper for OpenSearch index operations
  """
  alias Meadow.Search.{Alias, HTTP}
  alias Meadow.Search.Config, as: SearchConfig

  @doc """
  Create a timestamped index based on the config for the given schema and version.
  Returns `{:ok, {alias, index}}`
  """
  def create_from_schema(schema, version) do
    with target <- SearchConfig.alias_for(schema, version),
         settings <- SearchConfig.settings_for(schema, version) do
      case SearchConfig.search_pipeline_for(schema, version) do
        nil -> :noop
        pipeline -> create_search_pipeline(pipeline)
      end

      create(target, settings)
    end
  end

  @doc """
  Create a timestamped index based on the given alias name.
  Returns `{:ok, {alias, index}}`
  """
  def create(alias, settings \\ %{}) when is_binary(alias) and is_map(settings) do
    with timestamp <- DateTime.utc_now() |> DateTime.to_unix(:millisecond),
         new_index <- [alias, to_string(timestamp)] |> Enum.join("-") do
      case HTTP.put(new_index, json: settings) do
        {:ok, _response} -> {:ok, {alias, new_index}}
        other -> other
      end
    end
  end

  @doc """
  Create a search pipeline, takes a name, normalization_technique, combination_technique, and a weight field
  Returns name
  """
  def create_search_pipeline(
        name,
        normalization_technique \\ "l2",
        combination_technique \\ "arithmetic_mean",
        weights \\ [0.25, 0.75]
      ) do
    pipeline = %{
      "description" => "Search pipeline for #{name}",
      "phase_results_processors" => [
        %{
          "normalization-processor" => %{
            "normalization" => %{
              "technique" => normalization_technique
            },
            "combination" => %{
              "technique" => combination_technique,
              "parameters" => %{
                "weights" => weights
              }
            }
          }
        }
      ]
    }

    HTTP.put("_search/pipeline/#{name}", json: pipeline)
    name
  end

  @doc """
  Delete an index
  """
  def delete(index) do
    HTTP.delete(index)
  end

  @doc """
  Return a map of all indexes and their metadata starting with the optional binary prefix
  """
  def list(prefix \\ "") do
    with {:ok, %{body: body}} <-
           HTTP.get("_cluster/state/metadata?filter_path=metadata.indices") do
      body
      |> get_in(["metadata", "indices"])
      |> Enum.filter(fn {index, _} -> String.starts_with?(index, prefix) end)
      |> Enum.into(%{})
    end
  end

  @doc """
  Delete all indexes starting with a given alias prefix except for the `leave` latest.
  Always leave the `alias` pointing at the latest version of the index. Returns the list
  of remaining indexes.
  """
  def clean(alias, leave \\ 1) do
    alias
    |> list()
    |> extract_aliases()
    |> Enum.sort_by(fn {index, _} -> index end)
    |> Enum.reverse()
    |> Enum.drop(leave)
    |> Enum.each(fn {index, aliases} ->
      Alias.remove(index, aliases)
      delete(index)
    end)

    set_alias(alias)
    list(alias) |> Map.keys()
  end

  def refresh(target) do
    case HTTP.post("#{target}/_refresh") do
      {:ok, _} -> :ok
      other -> other
    end
  end

  defp set_alias(alias) do
    alias
    |> list()
    |> extract_aliases()
    |> Enum.sort_by(fn {index, _} -> index end)
    |> Enum.reverse()
    |> set_alias(alias)
  end

  defp set_alias([], _), do: []
  defp set_alias([{latest, _} | _], alias), do: Alias.update(alias, latest)

  defp extract_aliases(index_metadata) do
    index_metadata
    |> Enum.map(fn {index, %{"aliases" => aliases}} -> {index, aliases} end)
  end
end
