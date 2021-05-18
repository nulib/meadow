defmodule Meadow.Data.IndexerTest do
  @moduledoc false
  use Meadow.DataCase
  use Meadow.IndexCase
  alias Ecto.Adapters.SQL.Sandbox
  alias Meadow.Data.{Collections, FileSets, Indexer, Works}
  alias Meadow.Data.Schemas
  alias Meadow.Ingest.{Projects, Sheets}
  alias Meadow.Repo
  alias Mix.Tasks.Elasticsearch.Build, as: BuildTask

  describe "indexing" do
    setup do
      {:ok, indexable_data()}
    end

    test "synchronize_index/0", %{count: count} do
      assert indexed_doc_count() == 0
      Indexer.synchronize_index()
      assert indexed_doc_count() == count
    end

    test "reindex_all!/0", %{count: count} do
      Indexer.synchronize_index()
      assert indexed_doc_count() == count
      Indexer.reindex_all!()
      assert indexed_doc_count() == count
    end

    test "deleted", %{count: count, works: [work | _]} do
      assert indexed_doc_count() == 0
      Indexer.synchronize_index()
      assert indexed_doc_count() == count
      work |> Repo.delete()
      Indexer.synchronize_index()
      assert indexed_doc_count() == count - 3
    end
  end

  describe "dependent update triggers" do
    @tag unboxed: true
    test "collection title cascades to work" do
      Sandbox.unboxed_run(Repo, fn ->
        %{collection: collection, works: [work | _]} = indexable_data()

        Indexer.synchronize_index()
        assert indexed_doc(collection.id) |> get_in(["title"]) == collection.title
        assert indexed_doc(work.id) |> get_in(["collection", "title"]) == collection.title

        {:ok, collection} = collection |> Collections.update_collection(%{title: "New Title"})

        Indexer.synchronize_index()
        assert indexed_doc(collection.id) |> get_in(["title"]) == "New Title"
        assert indexed_doc(work.id) |> get_in(["collection", "title"]) == "New Title"
      end)
    end

    @tag unboxed: true
    test "work representative image change cascades to a collection" do
      Sandbox.unboxed_run(Repo, fn ->
        %{collection: collection, works: [work | _]} = indexable_data()
        Collections.set_representative_image(collection, work)

        Indexer.synchronize_index()

        assert indexed_doc(collection.id) |> get_in(["representativeImage", "workId"]) ==
                 work.id

        file_set = file_set_fixture(%{work_id: work.id})
        {:ok, work} = Works.update_work(work, %{file_sets: [file_set]})
        {:ok, work} = Works.set_representative_image(work, file_set)

        Indexer.synchronize_index()

        assert indexed_doc(work.id)
               |> get_in(["representativeFileSet", "fileSetId"]) == file_set.id

        assert indexed_doc(collection.id)
               |> get_in(["representativeImage", "url"]) == work.representative_image
      end)
    end

    @tag unboxed: true
    test "work visibility cascades to file set" do
      Sandbox.unboxed_run(Repo, fn ->
        %{works: [work | _], file_sets: [file_set | _]} = indexable_data()

        Indexer.synchronize_index()
        assert indexed_doc(work.id) |> get_in(["visibility", "id"]) == "OPEN"
        assert indexed_doc(file_set.id) |> get_in(["visibility", "id"]) == "OPEN"

        {:ok, work} =
          work
          |> Works.update_work(%{
            visibility: %{"id" => "RESTRICTED", "scheme" => "visibility"}
          })

        Indexer.synchronize_index()

        assert indexed_doc(work.id) |> get_in(["visibility"]) == %{
                 "id" => "RESTRICTED",
                 "label" => "Private",
                 "scheme" => "visibility"
               }

        assert indexed_doc(file_set.id) |> get_in(["visibility"]) == %{
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

        with doc <- indexed_doc(work.id) do
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

        with doc <- indexed_doc(work.id) do
          assert doc |> get_in(["sheet"]) == %{
                   "id" => ingest_sheet.id,
                   "title" => ingest_sheet.title
                 }
        end

        ingest_sheet |> Sheets.update_ingest_sheet(%{title: "New Title"})
        Indexer.synchronize_index()

        with doc <- indexed_doc(work.id) do
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

        with doc <- indexed_doc(work.id) do
          assert doc |> get_in(["project"]) == %{
                   "id" => project.id,
                   "title" => project.title
                 }
        end

        project |> Projects.update_project(%{title: "New Title"})
        Indexer.synchronize_index()

        with doc <- indexed_doc(work.id) do
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
    test "file_set metadata changes cascade to work" do
      Sandbox.unboxed_run(Repo, fn ->
        %{file_sets: [file_set | _]} = indexable_data()

        Indexer.synchronize_index()

        assert indexed_doc(file_set.id) |> get_in(["label"]) ==
                 nil

        {:ok, file_set} =
          file_set
          |> FileSets.update_file_set(%{
            metadata: %{label: "New Label", description: "New Description"}
          })

        work_updated_timestamp = Works.get_work!(file_set.work_id).updated_at

        Indexer.synchronize_index()
        assert indexed_doc(file_set.id) |> get_in(["label"]) == "New Label"

        assert indexed_doc(file_set.id) |> get_in(["description"]) ==
                 "New Description"

        assert indexed_doc(file_set.work_id) |> get_in(["modifiedDate"]) >
                 work_updated_timestamp
      end)
    end
  end

  describe "encoding" do
    setup do
      with %{collection: collection, works: works, file_sets: file_sets} <- indexable_data() do
        {:ok,
         %{
           collection: collection,
           work: List.first(works) |> Repo.preload(Schemas.Work.required_index_preloads()),
           file_set: List.first(file_sets) |> Repo.preload(:work)
         }}
      end
    end

    test "collection encoding", %{collection: subject} do
      [header, doc] = subject |> Indexer.encode!(:index) |> decode_njson()
      assert header |> get_in(["index", "_id"]) == subject.id
      assert doc |> get_in(["model", "application"]) == "Meadow"
      assert doc |> get_in(["model", "name"]) == "Collection"
      assert doc |> get_in(["title"]) == subject.title
    end

    test "work encoding", %{work: subject} do
      [header, doc] = subject |> Indexer.encode!(:index) |> decode_njson()
      assert header |> get_in(["index", "_id"]) == subject.id
      assert doc |> get_in(["model", "application"]) == "Meadow"
      assert doc |> get_in(["model", "name"]) == "Image"
      assert doc |> get_in(["fileSets"]) |> length == 2

      with metadata <- subject.descriptive_metadata do
        assert doc |> get_in(["descriptiveMetadata", "title"]) ==
                 metadata.title
      end

      with metadata <- subject.administrative_metadata do
        assert doc |> get_in(["administrativeMetadata", "projectName"]) == metadata.project_name
      end
    end

    test "file set encoding", %{file_set: subject} do
      [header, doc] = subject |> Indexer.encode!(:index) |> decode_njson()
      assert header |> get_in(["index", "_id"]) == subject.id
      assert doc |> get_in(["model", "application"]) == "Meadow"
      assert doc |> get_in(["model", "name"]) == "FileSet"
      assert doc |> get_in(["description"]) == subject.metadata.description
      assert doc |> get_in(["label"]) == subject.metadata.label
    end
  end

  describe "mix task" do
    setup do
      {:ok, indexable_data()}
    end

    test "mix elasticsearch.build", %{count: count} do
      assert indexed_doc_count() == 0

      ~w[meadow --cluster Meadow.ElasticsearchCluster]
      |> BuildTask.run()

      Elasticsearch.Index.refresh(Meadow.ElasticsearchCluster, "meadow")
      assert indexed_doc_count() == count
    end
  end
end
