defmodule Meadow.ElasticsearchStore do
  @moduledoc """
  Fetches data to upload to Elasticsearch
  """
  @behaviour Elasticsearch.Store

  alias Meadow.Data.Schemas
  alias Meadow.Repo

  @impl true
  def stream(Schemas.Work = schema) do
    schema
    |> Repo.stream()
    |> Stream.chunk_every(10)
    |> Stream.flat_map(fn chunk ->
      Repo.preload(chunk, :collection)
    end)
  end

  @impl true
  def stream(Schemas.FileSet = schema) do
    schema
    |> Repo.stream()
    |> Stream.chunk_every(10)
    |> Stream.flat_map(fn chunk ->
      Repo.preload(chunk, :work)
    end)
  end

  @impl true
  def stream(schema) do
    schema
    |> Repo.stream()
  end

  @impl true
  def transaction(fun) do
    {:ok, result} = Repo.transaction(fun, timeout: :infinity)
    result
  end
end
