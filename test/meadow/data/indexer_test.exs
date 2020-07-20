defmodule Meadow.Data.IndexerTest do
  @moduledoc false
  use Meadow.DataCase
  use Meadow.IndexCase
  alias Ecto.Adapters.SQL.Sandbox
  alias Meadow.Data.{Collections, Indexer, Works}
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
    test "collection name cascades to work" do
      Sandbox.unboxed_run(Repo, fn ->
        %{collection: collection, works: [work | _]} = indexable_data()

        Indexer.synchronize_index()
        assert indexed_doc(collection.id) |> get_in(["name"]) == collection.name
        assert indexed_doc(work.id) |> get_in(["collection", "name"]) == collection.name

        {:ok, collection} = collection |> Collections.update_collection(%{name: "New Name"})

        Indexer.synchronize_index()
        assert indexed_doc(collection.id) |> get_in(["name"]) == "New Name"
        assert indexed_doc(work.id) |> get_in(["collection", "name"]) == "New Name"
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
                   "name" => ingest_sheet.name
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
                   "name" => ingest_sheet.name
                 }
        end

        ingest_sheet |> Sheets.update_ingest_sheet(%{name: "New Name"})
        Indexer.synchronize_index()

        with doc <- indexed_doc(work.id) do
          assert doc |> get_in(["sheet"]) == %{
                   "id" => ingest_sheet.id,
                   "name" => "New Name"
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

        project |> Projects.update_project(%{title: "New Name"})
        Indexer.synchronize_index()

        with doc <- indexed_doc(work.id) do
          assert doc |> get_in(["project"]) == %{
                   "id" => project.id,
                   "title" => "New Name"
                 }
        end
      end)
    end
  end

  describe "encoding" do
    setup do
      with %{collection: collection, works: works, file_sets: file_sets} <- indexable_data() do
        {:ok,
         %{
           collection: collection,
           work:
             List.first(works) |> Repo.preload([:collection, :file_sets, :ingest_sheet, :project]),
           file_set: List.first(file_sets) |> Repo.preload(:work)
         }}
      end
    end

    test "collection encoding", %{collection: subject} do
      [header, doc] = subject |> Indexer.encode!(:index) |> decode_njson()
      assert header |> get_in(["index", "_id"]) == subject.id
      assert doc |> get_in(["model", "application"]) == "Meadow"
      assert doc |> get_in(["name"]) == subject.name
    end

    test "work encoding", %{work: subject} do
      [header, doc] = subject |> Indexer.encode!(:index) |> decode_njson()
      assert header |> get_in(["index", "_id"]) == subject.id
      assert doc |> get_in(["model", "application"]) == "Meadow"
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
