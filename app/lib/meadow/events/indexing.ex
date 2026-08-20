defmodule Meadow.Events.Indexing do
  @moduledoc """
  Handles events related to reindexing records in the search index.
  """

  use Retry
  import Ecto.Query

  alias Meadow.Data.IndexBatcher
  alias Meadow.Data.Schemas.{FileSet, Work}
  alias Meadow.Ingest.Schemas.Sheet

  use WalEx.Event, name: Meadow

  @cascade_fields %{
    file_sets_works:
      ~w[core_metadata derivatives extracted_metadata group_with poster_offset rank role structural_metadata]a,
    collections_file_sets: ~w[title]a,
    collections_works: ~w[title description]a,
    ingest_sheets_works: ~w[title]a,
    works_collections: ~w[representative_file_set_id]a,
    works_file_sets: ~w[published visibility]a
  }

  # Relational metadata tables whose rows belong to a work via `work_id`
  @work_metadata_tables ~w(
    work_descriptive_metadata work_administrative_metadata work_metadata_values
    work_controlled_entries work_notes work_related_urls work_dates_created work_nav_places
  )a

  def work_metadata_tables, do: @work_metadata_tables

  require Logger

  on_event(:all, fn events -> Enum.each(events, &handle_indexing/1) end)

  # A change to any metadata row reindexes its work; a title change also
  # cascades to the work's file sets (they index `work_title`)
  def handle_indexing(%{type: type, name: name, new_record: record} = event)
      when name in @work_metadata_tables and type in [:insert, :update] do
    IndexBatcher.reindex([record.work_id], :works)

    if name == :work_descriptive_metadata and
         Map.has_key?(Map.get(event, :changes) || %{}, :title) do
      from(fs in FileSet, where: fs.work_id == ^record.work_id) |> send_to_batcher(:file_sets)
    end
  end

  def handle_indexing(%{type: :delete, name: name, old_record: record})
      when name in @work_metadata_tables do
    IndexBatcher.reindex([record.work_id], :works)
  end

  def handle_indexing(%{type: :insert, name: name, new_record: record}) do
    IndexBatcher.reindex([record.id], name)
    do_insert_indexing(record, name)
  end

  def handle_indexing(%{type: :update, name: name, new_record: record, changes: changes}) do
    IndexBatcher.reindex([record.id], name)
    do_update_indexing(record, name, changes)
  end

  def handle_indexing(%{type: :delete, name: name, old_record: record}) do
    IndexBatcher.delete([record.id], name)
    do_delete_indexing(record, name)
  end

  defp do_insert_indexing(%{work_id: work_id}, :file_sets) do
    IndexBatcher.reindex([work_id], :works)
  end

  defp do_insert_indexing(%{collection_id: collection_id}, :works) do
    IndexBatcher.reindex([collection_id], :collections)
  end

  defp do_insert_indexing(%{file_set_id: file_set_id}, :file_set_annotations) do
    IndexBatcher.reindex([file_set_id], :file_sets)
  end

  defp do_insert_indexing(_, _), do: :noop

  defp do_update_indexing(%{id: id}, :collections, changes) do
    if Map.keys(changes) |> Enum.any?(&(&1 in @cascade_fields[:collections_works])) do
      from(w in Work, where: w.collection_id == ^id)
      |> send_to_batcher(:works)
    end

    if Map.keys(changes) |> Enum.any?(&(&1 in @cascade_fields[:collections_file_sets])) do
      from(fs in FileSet, join: w in Work, on: fs.work_id == w.id, where: w.collection_id == ^id)
      |> send_to_batcher(:file_sets)
    end
  end

  defp do_update_indexing(%{id: id, collection_id: collection_id}, :works, changes)
       when not is_nil(collection_id) do
    if Map.keys(changes) |> Enum.member?(:representative_file_set_id) do
      Logger.info("Updating collection #{collection_id} representative image")
      IndexBatcher.reindex([collection_id], :collections)
    end

    if Map.keys(changes) |> Enum.any?(&(&1 in @cascade_fields[:works_file_sets])) do
      from(fs in FileSet, where: fs.work_id == ^id)
      |> send_to_batcher(:file_sets)
    end
  end

  defp do_update_indexing(%{work_id: work_id}, :file_sets, changes) do
    if Map.keys(changes) |> Enum.any?(&(&1 in @cascade_fields[:file_sets_works])) do
      IndexBatcher.reindex([work_id], :works)
    end
  end

  defp do_update_indexing(%{file_set_id: file_set_id}, :file_set_annotations, _changes) do
    IndexBatcher.reindex([file_set_id], :file_sets)
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
    IndexBatcher.reindex([work_id], :works)
  end

  defp do_delete_indexing(%{file_set_id: file_set_id}, :file_set_annotations) do
    IndexBatcher.reindex([file_set_id], :file_sets)
  end

  defp do_delete_indexing(%{collection_id: collection_id}, :works)
       when not is_nil(collection_id) do
    IndexBatcher.reindex([collection_id], :collections)
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

  defp send_to_batcher(queryable, schema) do
    query = queryable |> select([q], q.id)
    repo = Application.get_env(:meadow, :indexing_repo)

    retry with: exponential_backoff() |> randomize() |> cap(10_000) |> Stream.take(10),
          rescue_only: [DBConnection.ConnectionError] do
      repo.all(query)
      |> IndexBatcher.reindex(schema)
    end
  end
end
