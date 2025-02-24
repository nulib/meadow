defmodule Meadow.Events.Indexing do
  @moduledoc """
  Handles events related to reindexing records in the search index.
  """

  import Ecto.Query

  alias Meadow.Data.IndexBatcher
  alias Meadow.Data.Schemas.{Collection, FileSet, Work}
  alias Meadow.Ingest.Schemas.Sheet
  alias Meadow.Repo.Indexing, as: IndexingRepo
  alias Meadow.Search.Bulk
  alias Meadow.Search.Config, as: SearchConfig

  @cascade_fields %{
    file_sets_works:
      ~w[core_metadata derivatives extracted_metadata poster_offset rank role structural_metadata]a,
    collections_works: ~w[title description]a,
    ingest_sheets_works: ~w[title]a,
    works_collections: ~w[representative_file_set_id],
    works_file_sets: ~w[published visibility]a
  }

  require Logger

  def handle_insert(%{name: name, new_record: record}) do
    IndexBatcher.reindex([record.id], name)
    do_insert_indexing(record, name)
  end

  def handle_update(%{name: name, new_record: record, changes: changes}) do
    IndexBatcher.reindex([record.id], name)
    do_update_indexing(record, name, changes)
  end

  def handle_delete(%{name: name, old_record: record}) do
    delete_from_index(name, record.id)
    do_delete_indexing(record, name)
  end

  # Reindex the work when a file set is inserted
  defp do_insert_indexing(%{work_id: work_id}, :file_sets) do
    IndexBatcher.reindex([work_id], :works)
  end

  # Reindex the collection when a work is inserted
  defp do_insert_indexing(%{collection_id: collection_id}, :works) do
    IndexBatcher.reindex([collection_id], :collections)
  end

  defp do_insert_indexing(_, _), do: :noop

  defp do_update_indexing(%{id: id}, :collections, changes) do
    if Map.keys(changes) |> Enum.any?(&(&1 in @cascade_fields[:collections_works])) do
      from(w in Work, where: w.collection_id == ^id)
      |> send_to_batcher(:works)
    end
  end

  defp do_update_indexing(%{id: id, collection_id: collection_id}, :works, changes)
       when not is_nil(collection_id) do
    if Map.keys(changes) |> Enum.any?(&(&1 in @cascade_fields[:works_collections])) do
      from(c in Collection, where: c.id == ^collection_id)
      |> send_to_batcher(:collections)
    end

    if Map.keys(changes) |> Enum.any?(&(&1 in @cascade_fields[:works_file_sets])) do
      from(fs in FileSet, where: fs.work_id == ^id)
      |> send_to_batcher(:file_sets)
    end
  end

  defp do_update_indexing(%{work_id: work_id}, :file_sets, changes) do
    if Map.keys(changes) |> Enum.any?(&(&1 in @cascade_fields[:file_sets_works])) do
      from(w in Work, where: w.id == ^work_id)
      |> send_to_batcher(:works)
    end
  end

  defp do_update_indexing(%{id: id}, :ingest_sheets, changes) do
    if Map.keys(changes) |> Enum.member?(:title) do
      from(w in Work, where: w.ingest_sheet_id == ^id)
      |> send_to_batcher(:works)
    end
  end

  defp do_update_indexing(%{id: id}, :projects, _) do
    from(w in Work, join: i in Sheet, on: w.ingest_sheet_id == i.id, where: i.project_id == ^id)
    |> send_to_batcher(:works)
  end

  defp do_update_indexing(_, _, _) do
    :noop
  end

  defp do_delete_indexing(%{work_id: work_id}, :file_sets) do
    from(w in Work, where: w.id == ^work_id)
    |> send_to_batcher(:works)
  end

  defp do_delete_indexing(%{collection_id: collection_id}, :works)
       when not is_nil(collection_id) do
    from(c in Collection, where: c.id == ^collection_id)
    |> send_to_batcher(:collections)
  end

  defp do_delete_indexing(%{id: id}, :ingest_sheets) do
    from(w in Work, where: w.ingest_sheet_id == ^id)
    |> send_to_batcher(:works)
  end

  defp do_delete_indexing(%{id: id}, :projects) do
    from(w in Work, join: i in Sheet, on: w.ingest_sheet_id == i.id, where: i.project_id == ^id)
    |> send_to_batcher(:works)
  end

  defp do_delete_indexing(%{id: id}, :collections) do
    from(w in Work, where: w.collection_id == ^id)
    |> send_to_batcher(:works)
  end

  defp do_delete_indexing(_, _) do
    :noop
  end

  defp delete_from_index(:collections, id), do: delete_from_schema_index(Collection, id)
  defp delete_from_index(:file_sets, id), do: delete_from_schema_index(FileSet, id)
  defp delete_from_index(:works, id), do: delete_from_schema_index(Work, id)
  defp delete_from_index(:ingest_sheets, _), do: :noop
  defp delete_from_index(:projects, _), do: :noop

  defp delete_from_schema_index(schema, id) do
    Logger.info("Deleting #{id} from #{schema} index")

    Bulk.delete([id], SearchConfig.alias_for(schema, 2))
  end

  defp send_to_batcher(queryable, schema) do
    queryable
    |> select([q], q.id)
    |> IndexingRepo.all()
    |> IndexBatcher.reindex(schema)
  end
end
