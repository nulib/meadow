defmodule Meadow.Search.BulkTest do
  use Meadow.DataCase
  use Meadow.IndexCase

  alias Meadow.Data.Indexer
  alias Meadow.Data.Schemas.Work
  alias Meadow.Repo
  alias Meadow.Search.{Bulk, Document, Index}
  alias Meadow.Search.Config, as: SearchConfig

  @target_version 2
  @target_index SearchConfig.alias_for(Work, @target_version)

  setup do
    data = indexable_data()
    Indexer.synchronize_index()

    {:ok, data}
  end

  test "delete/2", %{works: works, work_count: work_count} do
    assert indexed_doc_count(Work, @target_version) == {:ok, work_count}

    ids_to_delete = Enum.take(works, 2) |> Enum.map(& &1.id)
    Bulk.delete(ids_to_delete, @target_index)

    Index.refresh(@target_index)

    assert indexed_doc_count(Work, @target_version) == {:ok, work_count - 2}
  end

  test "upload/2", %{work_count: work_count} do
    assert indexed_doc_count(Work, @target_version) == {:ok, work_count}

    document =
      work_fixture()
      |> Repo.preload(Work.required_index_preloads())
      |> Document.encode(@target_version)

    Bulk.upload([document], @target_index)
    Index.refresh(@target_index)

    assert indexed_doc_count(Work, @target_version) == {:ok, work_count + 1}
  end
end
