defmodule Meadow.Data.IndexerTest do
  @moduledoc false
  use Honeybadger.Case
  # use Meadow.AuthorityCase
  use Meadow.DataCase
  use Meadow.IndexCase
  alias Ecto.Adapters.SQL.Sandbox
  alias Meadow.Data.{Collections, FileSets, Indexer, Works}
  alias Meadow.Data.Schemas.{Collection, FileSet, Work}
  alias Meadow.Ingest.{Projects, Sheets}
  alias Meadow.{Config, Repo}

  describe "indexing" do
    setup do
      {:ok, indexable_data()}
    end

    test "synchronize_index/0", context do
      assert_all_empty()
      Indexer.synchronize_index()
      assert_doc_counts_match(context)
    end

    test "reindex_all", context do
      Indexer.synchronize_index()
      assert_doc_counts_match(context)
      Indexer.reindex_all()
      assert_doc_counts_match(context)
      Indexer.reindex_all(2)
      assert_doc_counts_match(context)
      Indexer.reindex_all(2, Work)
      assert_doc_counts_match(context)
      Indexer.reindex_all(2, [FileSet, Collection])
      assert_doc_counts_match(context)
    end
  end

  describe "dependent update triggers" do
    @tag unboxed: true
    test "collection title cascades to work" do
      Sandbox.unboxed_run(Repo, fn ->
        %{collection: collection, works: [work | _]} = indexable_data()

        Indexer.synchronize_index()
        assert indexed_doc(Collection, 1, collection.id) |> get_in(["title"]) == collection.title

        assert indexed_doc(Work, 1, work.id) |> get_in(["collection", "title"]) ==
                 collection.title

        {:ok, collection} = collection |> Collections.update_collection(%{title: "New Title"})

        Indexer.synchronize_index()
        assert indexed_doc(Collection, 1, collection.id) |> get_in(["title"]) == "New Title"
        assert indexed_doc(Work, 1, work.id) |> get_in(["collection", "title"]) == "New Title"
      end)
    end

    @tag unboxed: true
    test "work representative image change cascades to a collection" do
      Sandbox.unboxed_run(Repo, fn ->
        %{collection: collection, works: [work | _]} = indexable_data()
        Collections.set_representative_image(collection, work)

        Indexer.synchronize_index()

        assert indexed_doc(Collection, 1, collection.id)
               |> get_in(["representativeImage", "workId"]) ==
                 work.id

        file_set = file_set_fixture(%{work_id: work.id})
        {:ok, work} = Works.update_work(work, %{file_sets: [file_set]})
        {:ok, work} = Works.set_representative_image(work, file_set)

        Indexer.synchronize_index()

        assert indexed_doc(Work, 1, work.id)
               |> get_in(["representativeFileSet", "fileSetId"]) == file_set.id

        assert indexed_doc(Collection, 1, collection.id)
               |> get_in(["representativeImage", "url"]) == work.representative_image
      end)
    end

    @tag unboxed: true
    test "work visibility cascades to file set" do
      Sandbox.unboxed_run(Repo, fn ->
        %{works: [work | _], file_sets: [file_set | _]} = indexable_data()

        Indexer.synchronize_index()
        assert indexed_doc(Work, 1, work.id) |> get_in(["visibility", "id"]) == "OPEN"
        assert indexed_doc(FileSet, 1, file_set.id) |> get_in(["visibility", "id"]) == "OPEN"

        {:ok, work} =
          work
          |> Works.update_work(%{
            visibility: %{"id" => "RESTRICTED", "scheme" => "visibility"}
          })

        Indexer.synchronize_index()

        assert indexed_doc(Work, 1, work.id) |> get_in(["visibility"]) == %{
                 "id" => "RESTRICTED",
                 "label" => "Private",
                 "scheme" => "visibility"
               }

        assert indexed_doc(FileSet, 1, file_set.id) |> get_in(["visibility"]) == %{
                 "id" => "RESTRICTED",
                 "label" => "Private",
                 "scheme" => "visibility"
               }
      end)
    end

    @tag unboxed: true
    test "work includes ingest sheet details" do
      Sandbox.unboxed_run(Repo, fn ->
        {project, ingest_sheet, work} = project_sheet_and_work()
        Indexer.synchronize_index()

        with doc <- indexed_doc(Work, 1, work.id) do
          assert doc |> get_in(["collection"]) == %{}
          assert doc |> get_in(["project"]) == %{"id" => project.id, "title" => project.title}

          assert doc |> get_in(["sheet"]) == %{
                   "id" => ingest_sheet.id,
                   "title" => ingest_sheet.title
                 }
        end
      end)
    end

    @tag unboxed: true
    test "ingest sheet change cascades to work" do
      Sandbox.unboxed_run(Repo, fn ->
        {_project, ingest_sheet, work} = project_sheet_and_work()
        Indexer.synchronize_index()

        with doc <- indexed_doc(Work, 1, work.id) do
          assert doc |> get_in(["sheet"]) == %{
                   "id" => ingest_sheet.id,
                   "title" => ingest_sheet.title
                 }
        end

        ingest_sheet |> Sheets.update_ingest_sheet(%{title: "New Title"})
        Indexer.synchronize_index()

        with doc <- indexed_doc(Work, 1, work.id) do
          assert doc |> get_in(["sheet"]) == %{
                   "id" => ingest_sheet.id,
                   "title" => "New Title"
                 }
        end
      end)
    end

    @tag unboxed: true
    test "project change cascades to work" do
      Sandbox.unboxed_run(Repo, fn ->
        {project, _ingest_sheet, work} = project_sheet_and_work()
        Indexer.synchronize_index()

        with doc <- indexed_doc(Work, 1, work.id) do
          assert doc |> get_in(["project"]) == %{
                   "id" => project.id,
                   "title" => project.title
                 }
        end

        project |> Projects.update_project(%{title: "New Title"})
        Indexer.synchronize_index()

        with doc <- indexed_doc(Work, 1, work.id) do
          assert doc |> get_in(["project"]) == %{
                   "id" => project.id,
                   "title" => "New Title"
                 }
        end
      end)
    end
  end

  describe "parent update triggers" do
    @tag unboxed: true
    test "file_set.core_metadata changes cascade to work" do
      Sandbox.unboxed_run(Repo, fn ->
        %{file_sets: [file_set | _]} = indexable_data()

        Indexer.synchronize_index()

        assert indexed_doc(FileSet, 1, file_set.id) |> get_in(["label"]) ==
                 nil

        {:ok, file_set} =
          file_set
          |> FileSets.update_file_set(%{
            core_metadata: %{label: "New Label", description: "New Description"}
          })

        work_updated_timestamp = Works.get_work!(file_set.work_id).updated_at

        Indexer.synchronize_index()
        assert indexed_doc(FileSet, 1, file_set.id) |> get_in(["label"]) == "New Label"

        assert indexed_doc(FileSet, 1, file_set.id) |> get_in(["description"]) ==
                 "New Description"

        assert indexed_doc(FileSet, 1, file_set.work_id) |> get_in(["modifiedDate"]) >
                 work_updated_timestamp
      end)
    end

    @tag unboxed: true
    test "file_set.derivatives changes cascade to work" do
      Sandbox.unboxed_run(Repo, fn ->
        %{file_sets: [file_set | _]} = indexable_data()

        Indexer.synchronize_index()

        assert indexed_doc(FileSet, 1, file_set.id) |> get_in(["representativeImageUrl"]) ==
                 nil

        {:ok, file_set} =
          file_set
          |> FileSets.update_file_set(%{
            derivatives: %{"poster" => "s3://foo/bar.tif"}
          })

        work = Works.get_work!(file_set.work_id)
        Works.set_representative_image!(work, file_set)

        Indexer.synchronize_index()

        assert indexed_doc(FileSet, 1, file_set.id) |> get_in(["representativeImageUrl"]) ==
                 "#{Config.iiif_server_url()}posters/#{file_set.id}"

        assert indexed_doc(FileSet, 1, file_set.work_id) |> get_in(["modifiedDate"]) >
                 work.updated_at

        assert indexed_doc(FileSet, 1, file_set.work_id)
               |> get_in(["representativeFileSet", "url"]) ==
                 "#{Config.iiif_server_url()}posters/#{file_set.id}"
      end)
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
