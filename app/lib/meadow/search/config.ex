defmodule Meadow.Search.Config do
  @moduledoc """
  Convenience methods for retrieving search-specific configuration
  """

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
    case config_for(schema, version) do
      %{settings: settings, pipeline: pipeline} ->
        File.read!(settings)
        |> Jason.decode!()
        |> put_in(["settings", "default_pipeline"], pipeline)

      %{settings: settings} ->
        File.read!(settings) |> Jason.decode!()

      _ ->
        nil
    end
  end

  def embedding_model_id do
    Application.get_env(:meadow, Meadow.Search.Cluster)
    |> Keyword.get(:embedding_model_id)
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
