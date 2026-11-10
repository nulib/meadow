defmodule Meadow.Search.Config do
  @moduledoc """
  Convenience methods for retrieving search-specific configuration
  """
  alias Meadow.Embeddings.Config, as: EmbeddingsConfig

  def index_configs do
    Application.get_env(:meadow, Meadow.Search.Cluster)
    |> Keyword.get(:indexes)
  end

  def aliases do
    index_configs()
    |> Enum.map(& &1.name)
  end

  def config_for(schema, version) do
    Enum.find(index_configs(), fn %{version: index_version, schemas: index_schemas} ->
      index_version == version && Enum.member?(index_schemas, schema)
    end)
  end

  def alias_for(schema, version) do
    case config_for(schema, version) do
      %{name: name} -> name
      _ -> nil
    end
  end

  @doc """
  Index settings for a schema, with the `embedding` field (when the mapping
  has one) sized to the vectors `Meadow.Embeddings` produces.
  """
  def settings_for(schema, version) do
    case config_for(schema, version) do
      %{settings: settings} ->
        settings
        |> File.read!()
        |> Jason.decode!()
        |> add_embedding_dimension()

      _ ->
        nil
    end
  end

  @doc "The name of the search pipeline for a schema, if it has one"
  def search_pipeline_for(schema, version) do
    case config_for(schema, version) do
      %{pipeline: pipeline} -> pipeline
      _ -> nil
    end
  end

  def add_embedding_dimension(
        %{"mappings" => %{"properties" => %{"embedding" => %{"dimension" => _}}}} = settings
      ) do
    put_in(
      settings,
      ["mappings", "properties", "embedding", "dimension"],
      EmbeddingsConfig.dimensions()
    )
  end

  def add_embedding_dimension(settings), do: settings

  def index_versions do
    index_configs()
    |> Enum.map(& &1.version)
    |> Enum.uniq()
  end

  @doc "Retrieve Search Cluster URL"
  def cluster_url do
    Application.get_env(:meadow, Meadow.Search.Cluster)
    |> Keyword.get(:url)
  end

  def bulk_page_size do
    Application.get_env(:meadow, Meadow.Search.Cluster)
    |> Keyword.get(:bulk_page_size)
  end

  def bulk_request_limit do
    Application.get_env(:meadow, Meadow.Search.Cluster)
    |> Keyword.get(:bulk_request_limit)
  end

  def bulk_wait_interval do
    Application.get_env(:meadow, Meadow.Search.Cluster)
    |> Keyword.get(:bulk_wait_interval)
  end

  def model_for(schema) do
    schema
    |> to_string()
    |> String.split(".")
    |> List.last()
  end

  def reindex_poll_interval do
    Application.get_env(:meadow, Meadow.Search.Cluster)
    |> Keyword.get(:reindex_poll_interval, 5_000)
  end
end
