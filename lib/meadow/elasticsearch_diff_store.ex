defmodule Meadow.ElasticsearchDiffStore do
  @moduledoc """
  Fetches records that are out of sync with Elasticsearch as tracked
  by the IndexTime table
  """
  @behaviour Elasticsearch.Store

  alias Meadow.Data.Schemas
  alias Meadow.Data.{Collections, Works}
  alias Meadow.Ingest.Sheets
  alias Meadow.Repo
  import Ecto.Query

  @chunk_size 100
  @tracked_schemas [Schemas.Collection, Schemas.Work, Schemas.FileSet]

  @impl true
  def stream(:deleted) do
    from(t in Schemas.IndexTime,
      select: t.id,
      except: ^all_ids(@tracked_schemas)
    )
    |> Repo.stream()
  end

  @impl true
  def stream(Schemas.Work = schema) do
    schema
    |> out_of_date()
    |> Sheets.works_with_sheets()
    |> Repo.stream()
    |> Stream.chunk_every(@chunk_size)
    |> Stream.flat_map(fn chunk ->
      chunk
      |> Repo.preload([:collection, :file_sets])
      |> Works.add_representative_image()
    end)
  end

  @impl true
  def stream(Schemas.Collection = schema) do
    schema
    |> out_of_date()
    |> Repo.stream()
    |> Stream.chunk_every(@chunk_size)
    |> Stream.flat_map(fn chunk ->
      chunk
      |> Repo.preload(:representative_work)
      |> Collections.add_representative_image()
    end)
  end

  @impl true
  def stream(Schemas.FileSet = schema) do
    schema
    |> out_of_date()
    |> Repo.stream()
    |> Stream.chunk_every(@chunk_size)
    |> Stream.flat_map(fn chunk ->
      Repo.preload(chunk, :work)
    end)
  end

  @impl true
  def stream(schema) do
    schema
    |> out_of_date()
    |> Repo.stream()
  end

  @impl true
  def transaction(fun) do
    {:ok, result} = Repo.transaction(fun, timeout: :infinity)
    result
  end

  defp all_ids([queryable | []]), do: all_ids(queryable)

  defp all_ids([queryable | queryables]) do
    all_ids(queryable) |> union(^all_ids(queryables))
  end

  defp all_ids(queryable), do: from(row in queryable, select: row.id)

  defp out_of_date(queryable) do
    from(r in queryable,
      left_join: t in Schemas.IndexTime,
      on: r.id == t.id,
      where: is_nil(t.indexed_at) or t.indexed_at < r.updated_at,
      select: r
    )
  end
end
