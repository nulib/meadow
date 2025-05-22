defmodule Meadow.Search.BulkTest do
  use Meadow.DataCase
  use Meadow.IndexCase

  alias Meadow.Data.Indexer
  alias Meadow.Data.Schemas.Work
  alias Meadow.Repo
  alias Meadow.Search.{Bulk, Document, Index}
  alias Meadow.Search.Config, as: SearchConfig

  import ExUnit.CaptureLog

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

  describe "large document bulks" do
    setup do
      cluster_config = Application.get_env(:meadow, Meadow.Search.Cluster)
      updated_config = Keyword.put(cluster_config, :bulk_request_limit, 2_500)
      Application.put_env(:meadow, Meadow.Search.Cluster, updated_config)

      on_exit(fn ->
        Application.put_env(:meadow, Meadow.Search.Cluster, cluster_config)
      end)
    end

    test "upload/2 with large documents", %{work_count: work_count} do
      assert indexed_doc_count(Work, @target_version) == {:ok, work_count}

      document_1 =
        work_fixture()
        |> Repo.preload(Work.required_index_preloads())
        |> Document.encode(@target_version)

      document_2 =
        work_fixture()
        |> Repo.preload(Work.required_index_preloads())
        |> Document.encode(@target_version)

      assert capture_log(fn ->
        Bulk.upload([document_1, document_2], @target_index)
      end) =~ "Uploading 1 document ("

      Index.refresh(@target_index)

      assert indexed_doc_count(Work, @target_version) == {:ok, work_count + 2}
    end
  end
end
