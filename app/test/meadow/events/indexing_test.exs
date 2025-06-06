defmodule Meadow.Events.IndexingTest do
  @moduledoc false
  use Honeybadger.Case
  # use Meadow.AuthorityCase
  use Meadow.DataCase, async: false
  use Meadow.IndexCase
  alias Meadow.Data.{Collections, FileSets, IndexBatcher, Indexer, Works}
  alias Meadow.Data.Schemas.{Collection, FileSet, Work}
  alias Meadow.Ingest.{Projects, Sheets}
  alias Meadow.{Config, Repo}
  alias Meadow.Search.Config, as: SearchConfig
  alias Meadow.Search.HTTP, as: SearchHTTP

  import Assertions
  import ExUnit.CaptureLog

  def assert_flushed(schema) do
    assert_async(timeout: 2000) do
      assert IndexBatcher.flush(schema) > 0
    end
  end

  @moduletag walex: [Meadow.Events.Indexing]
  describe "indexing" do
    setup do
      for schema <- [Work, Collection, FileSet] do
        IndexBatcher.child_spec(schema, flush_interval: :never)
        |> start_supervised!()
      end

      {:ok, indexable_data()}
    end

    test "handle_insert/1", context do
      assert_all_empty()
      assert_flushed(:all)
      assert_doc_counts_match(context)
    end

    test "error_handling", context do
      assert_all_empty()
      assert_flushed(:all)
      %{file_sets: [file_set | _]} = context

      logged =
        capture_log(fn ->
          file_set
          |> Ecto.Changeset.change(%{core_metadata: nil})
          |> Repo.update()

          assert_flushed(:file_sets)
        end)

      assert String.contains?(
               logged,
               "id=#{file_set.id} [error] Index encoding failed due to: ** (KeyError)"
             )
    end

    test "reindex_all", context do
      assert_flushed(:all)
      assert_doc_counts_match(context)
      Indexer.reindex_all()
      assert_doc_counts_match(context)
      Indexer.reindex_all(2)
      assert_doc_counts_match(context)
      Indexer.reindex_all(2, Work)
      assert_doc_counts_match(context)
      Indexer.reindex_all(2, [FileSet, Collection])
      assert_doc_counts_match(context)

      {:ok, %{body: body}} = SearchHTTP.get("_cat/indices")
      lines = String.split(body, "\n")

      [Work, Collection, FileSet]
      |> Enum.each(fn schema ->
        index = SearchConfig.alias_for(schema, 2)
        assert Enum.filter(lines, &String.contains?(&1, "#{index}-")) |> length() == 1
      end)
    end
  end

  describe "dependent updates" do
    setup do
      for schema <- [Work, Collection, FileSet] do
        IndexBatcher.child_spec(schema, flush_interval: :never)
        |> start_supervised!()
      end

      {:ok, indexable_data()}
    end

    test "collection title cascades to work", %{collection: collection, works: [work | _]} do
      assert_flushed(:all)
      assert indexed_doc(Collection, 2, collection.id) |> get_in(["title"]) == collection.title

      assert indexed_doc(Work, 2, work.id) |> get_in(["collection", "title"]) ==
               collection.title

      {:ok, collection} = collection |> Collections.update_collection(%{title: "New Title"})

      assert_flushed(:all)
      assert indexed_doc(Collection, 2, collection.id) |> get_in(["title"]) == "New Title"
      assert indexed_doc(Work, 2, work.id) |> get_in(["collection", "title"]) == "New Title"
    end

    test "work representative image change cascades to a collection" do
      %{collection: collection} = indexable_data()
      %{works: [work | _]} = Repo.preload(collection, :works)
      assert_flushed(:all)

      logged =
        capture_log(fn ->
          Collections.set_representative_image(collection, work)
          assert_flushed(:all)
        end)

      assert String.contains?(
               logged,
               "Flushing 1 Elixir.Meadow.Data.Schemas.Collection updated documents"
             )

      logged =
        capture_log(fn ->
          file_set = file_set_fixture(%{work_id: work.id})
          {:ok, work} = Works.update_work(work, %{file_sets: [file_set]})
          IndexBatcher.clear(:all)

          {:ok, _work} = Works.set_representative_image(work, file_set)
          assert_flushed(:collections)
        end)

      assert String.contains?(
               logged,
               "Flushing 1 Elixir.Meadow.Data.Schemas.Collection updated documents"
             )

      assert String.contains?(logged, "Updating collection #{collection.id} representative image")
    end

    test "work visibility cascades to file set" do
      %{works: [work | _], file_sets: [file_set | _]} = indexable_data()

      assert_flushed(:all)
      assert indexed_doc(Work, 2, work.id) |> get_in(["visibility"]) == "Public"
      assert indexed_doc(FileSet, 2, file_set.id) |> get_in(["visibility"]) == "Public"

      {:ok, work} =
        work
        |> Works.update_work(%{
          visibility: %{"id" => "RESTRICTED", "scheme" => "visibility"}
        })

      assert_flushed(:all)

      assert indexed_doc(Work, 2, work.id) |> get_in(["visibility"]) == "Private"

      assert indexed_doc(FileSet, 2, file_set.id) |> get_in(["visibility"]) == "Private"
    end

    test "work includes ingest sheet details" do
      {project, ingest_sheet, work} = project_sheet_and_work()
      assert_flushed(:all)

      with doc <- indexed_doc(Work, 2, work.id) do
        assert doc |> get_in(["collection"]) == nil

        assert doc |> get_in(["ingest_project"]) == %{
                 "id" => project.id,
                 "title" => project.title
               }

        assert doc |> get_in(["ingest_sheet"]) == %{
                 "id" => ingest_sheet.id,
                 "title" => ingest_sheet.title
               }
      end
    end

    test "ingest sheet change cascades to work" do
      {_project, ingest_sheet, work} = project_sheet_and_work()
      assert_flushed(:all)

      with doc <- indexed_doc(Work, 2, work.id) do
        assert doc |> get_in(["ingest_sheet"]) == %{
                 "id" => ingest_sheet.id,
                 "title" => ingest_sheet.title
               }
      end

      ingest_sheet |> Sheets.update_ingest_sheet(%{title: "New Title"})
      assert_flushed(:all)

      with doc <- indexed_doc(Work, 2, work.id) do
        assert doc |> get_in(["ingest_sheet"]) == %{
                 "id" => ingest_sheet.id,
                 "title" => "New Title"
               }
      end
    end

    test "project change cascades to work" do
      {project, _ingest_sheet, work} = project_sheet_and_work()
      assert_flushed(:all)

      with doc <- indexed_doc(Work, 2, work.id) do
        assert doc |> get_in(["ingest_project"]) == %{
                 "id" => project.id,
                 "title" => project.title
               }
      end

      project |> Projects.update_project(%{title: "New Title"})
      assert_flushed(:all)

      with doc <- indexed_doc(Work, 2, work.id) do
        assert doc |> get_in(["ingest_project"]) == %{
                 "id" => project.id,
                 "title" => "New Title"
               }
      end
    end
  end

  describe "parent update triggers" do
    setup do
      for schema <- [Work, Collection, FileSet] do
        IndexBatcher.child_spec(schema, flush_interval: :never)
        |> start_supervised!()
      end

      :ok
    end

    test "file_set.core_metadata changes cascade to work" do
      %{file_sets: [file_set | _]} = indexable_data()

      assert_flushed(:all)

      assert indexed_doc(FileSet, 2, file_set.id) |> get_in(["label"]) ==
               nil

      {:ok, file_set} =
        file_set
        |> FileSets.update_file_set(%{
          core_metadata: %{label: "New Label", description: "New Description"}
        })

      work_updated_timestamp = Works.get_work!(file_set.work_id).updated_at

      assert_flushed(:all)
      assert indexed_doc(FileSet, 2, file_set.id) |> get_in(["label"]) == "New Label"

      assert indexed_doc(FileSet, 2, file_set.id) |> get_in(["description"]) ==
               "New Description"

      assert indexed_doc(Work, 2, file_set.work_id) |> get_in(["modified_date"]) >
               work_updated_timestamp
    end

    test "file_set.derivatives changes cascade to work" do
      %{file_sets: [file_set | _]} = indexable_data()

      assert_flushed(:all)

      assert indexed_doc(FileSet, 2, file_set.id) |> get_in(["representative_image_url"]) ==
               nil

      {:ok, file_set} =
        file_set
        |> FileSets.update_file_set(%{
          derivatives: %{"poster" => "s3://foo/bar.tif"}
        })

      work = Works.get_work!(file_set.work_id)
      Works.set_representative_image!(work, file_set)

      assert_flushed(:all)

      assert indexed_doc(FileSet, 2, file_set.id) |> get_in(["representative_image_url"]) ==
               "#{Config.iiif_server_url()}posters/#{file_set.id}"

      assert indexed_doc(Work, 2, file_set.work_id) |> get_in(["modified_date"]) >
               work.updated_at

      assert indexed_doc(Work, 2, file_set.work_id)
             |> get_in(["representative_file_set", "url"]) ==
               "#{Config.iiif_server_url()}posters/#{file_set.id}"
    end
  end

  describe "error reporting" do
    @describetag :skip

    setup do
      {:ok, _} = Honeybadger.API.start(self())
      on_exit(&Honeybadger.API.stop/0)

      fake_metadata = %{
        "tool" => "mediainfo",
        "tool_version" => "21.09",
        "value" => %{"media" => %{}}
      }

      %{file_sets: [file_set_1 | [file_set_2 | _]]} = indexable_data()

      file_set_1
      |> FileSets.update_file_set(%{
        extracted_metadata: %{mediainfo: Jason.encode!(fake_metadata)}
      })

      file_set_2 |> FileSets.update_file_set(%{extracted_metadata: %{mediainfo: fake_metadata}})
      :ok
    end

    test "indexing errors reported to Honeybadger" do
      restart_with_config(exclude_envs: [])
      Indexer.reindex_all()
      assert_receive {:api_request, report_1}, 2500
      assert_receive {:api_request, report_2}, 2500

      assert [report_1, report_2]
             |> Enum.all?(&(get_in(&1, ["error", "class"]) == "Meadow.IndexerError"))
    end
  end
end
