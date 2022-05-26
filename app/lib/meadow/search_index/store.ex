defmodule Meadow.SearchIndex.Store do
  @moduledoc """
  Fetches data to upload to the search index
  """
  alias Meadow.Data.Schemas
  alias Meadow.Data.{Collections, Works}
  alias Meadow.Repo

  def stream(Schemas.Work = schema) do
    schema
    |> Repo.stream()
    |> Stream.chunk_every(10)
    |> Stream.flat_map(fn chunk ->
      chunk
      |> Repo.preload(Schemas.Work.required_index_preloads())
      |> Works.add_representative_image()
    end)
  end

  def stream(Schemas.FileSet = schema) do
    schema
    |> Repo.stream()
    |> Stream.chunk_every(10)
    |> Stream.flat_map(fn chunk ->
      Repo.preload(chunk, :work)
    end)
  end

  def stream(Schemas.Collection = schema) do
    schema
    |> Repo.stream()
    |> Stream.chunk_every(10)
    |> Stream.flat_map(fn chunk ->
      chunk
      |> Repo.preload(:representative_work)
      |> Collections.add_representative_image()
    end)
  end

  def stream(schema) do
    schema
    |> Repo.stream()
  end

  def transaction(fun) do
    {:ok, result} = Repo.transaction(fun, timeout: :infinity)
    result
  end
end
