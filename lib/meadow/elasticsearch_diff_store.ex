defmodule Meadow.ElasticsearchDiffStore do
  @moduledoc """
  Fetches records that are out of sync with Elasticsearch as tracked
  by the IndexTime table
  """
  @behaviour Elasticsearch.Store

  alias Meadow.Data.Schemas
  alias Meadow.Data.{Collections, Works}
  alias Meadow.Repo
  import Ecto.Query

  @chunk_size 500
  @tracked_schemas [Schemas.Collection, Schemas.Work, Schemas.FileSet]

  @impl true
  def stream(schema) do
    Stream.resource(
      fn -> schema end,
      fn schema ->
        case retrieve(schema) do
          [] -> {:halt, schema}
          records -> {records, schema}
        end
      end,
      fn _ -> :noop end
    )
  end

  defp retrieve(:deleted) do
    from(t in Schemas.IndexTime,
      select: t.id,
      except: ^all_ids(@tracked_schemas)
    )
    |> Repo.all()
  end

  defp retrieve(Schemas.Work = schema) do
    with preloads <- Schemas.Work.required_index_preloads() do
      schema
      |> out_of_date()
      |> limit(@chunk_size)
      |> preload(^preloads)
      |> Repo.all()
      |> Works.add_representative_image()
    end
  end

  defp retrieve(Schemas.Collection = schema) do
    schema
    |> out_of_date()
    |> limit(@chunk_size)
    |> preload(:representative_work)
    |> Repo.all()
    |> Collections.add_representative_image()
  end

  defp retrieve(Schemas.FileSet = schema) do
    schema
    |> out_of_date()
    |> limit(@chunk_size)
    |> preload(:work)
    |> Repo.all()
  end

  defp retrieve(schema) do
    schema
    |> out_of_date()
    |> Repo.all()
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
