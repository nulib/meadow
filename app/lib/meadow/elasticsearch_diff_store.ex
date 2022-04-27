defmodule Meadow.ElasticsearchDiffStore do
  @moduledoc """
  Fetches records that are out of sync with Elasticsearch as tracked
  by the IndexTime table
  """
  alias Meadow.Data.Schemas
  alias Meadow.Data.{Collections, Works}
  alias Meadow.Repo
  import Ecto.Query

  @chunk_size 500
  @tracked_schemas [Schemas.Collection, Schemas.Work, Schemas.FileSet]

  def retrieve(schema, limit \\ @chunk_size)

  def retrieve(:deleted, limit) do
    from(t in Schemas.IndexTime,
      select: t.id,
      except: ^all_ids(@tracked_schemas)
    )
    |> limit(^limit)
    |> Repo.all()
  end

  def retrieve(Schemas.Work = schema, limit) do
    with preloads <- Schemas.Work.required_index_preloads() do
      schema
      |> out_of_date()
      |> limit(^limit)
      |> preload(^preloads)
      |> Repo.all()
      |> Works.add_representative_image()
    end
  end

  def retrieve(Schemas.Collection = schema, limit) do
    schema
    |> out_of_date()
    |> limit(^limit)
    |> preload(:representative_work)
    |> Repo.all()
    |> Collections.add_representative_image()
  end

  def retrieve(Schemas.FileSet = schema, limit) do
    schema
    |> out_of_date()
    |> limit(^limit)
    |> preload(:work)
    |> Repo.all()
  end

  def retrieve(schema, limit) do
    schema
    |> out_of_date()
    |> limit(^limit)
    |> Repo.all()
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
