defmodule Meadow.Search.Config do
  @moduledoc """
  Convenience methods for retrieving search-specific configuration
  """
  require Logger

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

  def settings_for(schema, version) do
    case {config_for(schema, version), embedding_model_id()} do
      {%{settings: settings, pipeline: pipeline}, nil} ->
        Logger.warning("No embedding model id found in config, skipping pipeline: #{pipeline}")
        File.read!(settings) |> Jason.decode!()

      {%{settings: settings, pipeline: pipeline}, _embedding_model_id} ->
        File.read!(settings)
        |> Jason.decode!()
        |> put_in(["settings", "default_pipeline"], pipeline)
        |> add_embedding_dimension()

      {%{settings: settings}, _} ->
        File.read!(settings) |> Jason.decode!()

      _ ->
        nil
    end
  end

  def embedding_model_id do
    Application.get_env(:meadow, Meadow.Search.Cluster)
    |> Keyword.get(:embedding_model_id)
  end

  def add_embedding_dimension(
        %{"mappings" => %{"properties" => %{"embedding" => %{"dimension" => _}}}} = settings
      ) do
    case embedding_model_dimensions() do
      nil -> settings
      _ -> insert_embedding_dimension(settings)
    end
  end

  def insert_embedding_dimension(settings),
    do:
      put_in(
        settings,
        ["mappings", "properties", "embedding", "dimension"],
        embedding_model_dimensions()
      )

  def embedding_model_dimensions do
    Application.get_env(:meadow, Meadow.Search.Cluster)
    |> Keyword.get(:embedding_dimensions)
  end

  def embedding_text_fields do
    Application.get_env(:meadow, Meadow.Search.Cluster)
    |> Keyword.get(:embedding_text_fields)
  end

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
end
