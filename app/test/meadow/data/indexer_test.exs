defmodule Meadow.Data.IndexerTest do
  @moduledoc false
  use Honeybadger.Case
  use Meadow.AuthorityCase
  use Meadow.DataCase
  use Meadow.IndexCase
  alias Ecto.Adapters.SQL.Sandbox
  alias Meadow.Data.{CodedTerms, Collections, FileSets, Indexer, Schemas, Works}
  alias Meadow.Ingest.{Projects, Sheets}
  alias Meadow.{Config, Repo}
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
    test "file_set.core_metadata changes cascade to work" do
      Sandbox.unboxed_run(Repo, fn ->
        %{file_sets: [file_set | _]} = indexable_data()

        Indexer.synchronize_index()

        assert indexed_doc(file_set.id) |> get_in(["label"]) ==
                 nil

        {:ok, file_set} =
          file_set
          |> FileSets.update_file_set(%{
            core_metadata: %{label: "New Label", description: "New Description"}
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

    @tag unboxed: true
    test "file_set.derivatives changes cascade to work" do
      Sandbox.unboxed_run(Repo, fn ->
        %{file_sets: [file_set | _]} = indexable_data()

        Indexer.synchronize_index()

        assert indexed_doc(file_set.id) |> get_in(["representativeImageUrl"]) ==
                 nil

        {:ok, file_set} =
          file_set
          |> FileSets.update_file_set(%{
            derivatives: %{"poster" => "s3://foo/bar.tif"}
          })

        work = Works.get_work!(file_set.work_id)
        Works.set_representative_image!(work, file_set)

        Indexer.synchronize_index()

        assert indexed_doc(file_set.id) |> get_in(["representativeImageUrl"]) ==
                 "#{Config.iiif_server_url()}posters/#{file_set.id}"

        assert indexed_doc(file_set.work_id) |> get_in(["modifiedDate"]) >
                 work.updated_at

        assert indexed_doc(file_set.work_id) |> get_in(["representativeFileSet", "url"]) ==
                 "#{Config.iiif_server_url()}posters/#{file_set.id}"
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
      assert doc |> get_in(["model", "name"]) == "Work"
      assert doc |> get_in(["fileSets"]) |> length == 2
      assert doc |> get_in(["fileSets"]) |> List.first() |> map_size() == 10

      with metadata <- subject.descriptive_metadata do
        assert doc |> get_in(["descriptiveMetadata", "title"]) ==
                 metadata.title
      end

      with metadata <- subject.administrative_metadata do
        assert doc |> get_in(["administrativeMetadata", "projectName"]) == metadata.project_name
      end
    end

    test "work encodes thumbnail field", %{work: subject} do
      [_header, doc] = subject |> Indexer.encode!(:index) |> decode_njson()
      assert is_nil(doc |> get_in(["thumbnail"]))

      file_set = subject.file_sets |> Enum.at(1)
      derivatives = FileSets.add_derivative(file_set, :poster, FileSets.poster_uri_for(file_set))
      {:ok, file_set} = FileSets.update_file_set(file_set, %{derivatives: derivatives})
      {:ok, subject} = Works.set_representative_image(subject, file_set)

      Indexer.synchronize_index()
      [_header, doc] = subject |> Indexer.encode!(:index) |> decode_njson()

      assert doc |> get_in(["thumbnail"]) ==
               "http://localhost:8184/iiif/2/posters/#{file_set.id}/full/!300,300/0/default.jpg"
    end

    test "work encode of copy fields", %{work: subject} do
      {:ok, subject} =
        subject
        |> Works.update_work(%{
          descriptive_metadata: %{
            alternate_title: ["Alt Title 1", "Alt Title 2"],
            creator: [%{term: %{id: "mock1:result1"}}],
            date_created: [%{edtf: "~1899"}],
            contributor: [
              %{role: %{id: "aut", scheme: "marc_relator"}, term: %{id: "mock1:result1"}}
            ],
            subject: [
              %{
                role: %{id: "GEOGRAPHICAL", scheme: "subject_role"},
                term: %{id: "mock1:result1"}
              }
            ]
          }
        })

      Indexer.synchronize_index()
      [_header, doc] = subject |> Indexer.encode!(:index) |> decode_njson()
      assert doc |> get_in(["title"]) == subject.descriptive_metadata.title
      assert doc |> get_in(["alternateTitle"]) == subject.descriptive_metadata.alternate_title
      assert doc |> get_in(["collectionTitle"]) == subject.collection.title

      creators =
        Enum.map(subject.descriptive_metadata.creator, fn creator -> creator.term.label end)

      assert doc |> get_in(["creator"]) == creators

      contributors =
        Enum.map(subject.descriptive_metadata.contributor, fn contributor ->
          contributor.term.label <>
            " (" <> CodedTerms.label(contributor.role.id, "marc_relator") <> ")"
        end)

      assert doc |> get_in(["contributor"]) == contributors

      subjects = Enum.map(subject.descriptive_metadata.subject, fn s -> s.term.label end)

      assert doc |> get_in(["subject"]) == subjects

      dates = Enum.map(subject.descriptive_metadata.date_created, fn d -> d.humanized end)

      assert doc |> get_in(["dateCreated"]) == dates
    end

    test "file set encoding", %{file_set: subject} do
      derivatives = FileSets.add_derivative(subject, :poster, FileSets.poster_uri_for(subject))

      {:ok, subject} =
        subject
        |> FileSets.update_file_set(%{
          derivatives: derivatives,
          poster_offset: 100,
          structural_metadata: %{
            type: "webvtt",
            value:
              "WEBVTT\n\n00:00:00.500 --> 00:00:02.000\nThe Web is always changing\n\n00:00:02.500 --> 00:00:04.300\nand the way we access it is changing"
          }
        })

      subject = FileSets.get_file_set_with_work_and_sheet!(subject.id)

      [header, doc] = subject |> Indexer.encode!(:index) |> decode_njson()
      assert header |> get_in(["index", "_id"]) == subject.id
      assert doc |> get_in(["model", "application"]) == "Meadow"
      assert doc |> get_in(["model", "name"]) == "FileSet"
      assert doc |> get_in(["description"]) == subject.core_metadata.description
      assert doc |> get_in(["digests"]) == subject.core_metadata.digests
      assert doc |> get_in(["label"]) == subject.core_metadata.label
      assert doc |> get_in(["posterOffset"]) == 100
      assert doc |> get_in(["webvtt"]) == subject.structural_metadata.value
      assert doc |> get_in(["rank"]) == subject.rank

      assert doc |> get_in(["streamingUrl"]) == Path.join(Config.streaming_url(), "bar.m3u8")

      poster_url =
        with uri <- URI.parse(Config.iiif_server_url()) do
          uri
          |> URI.merge("posters/#{subject.id}")
          |> URI.to_string()
        end

      assert doc |> get_in(["representativeImageUrl"]) == poster_url
    end

    test "file set encoding with bad EXIF data (empty string)", %{file_set: subject} do
      {:ok, subject} =
        subject
        |> FileSets.update_file_set(%{
          extracted_metadata: %{exif: ""}
        })

      subject = FileSets.get_file_set_with_work_and_sheet!(subject.id)

      [header, doc] = subject |> Indexer.encode!(:index) |> decode_njson()
      assert header |> get_in(["index", "_id"]) == subject.id
      assert doc |> get_in(["extractedMetadata"]) == %{"exif" => %{}}
    end
  end

  describe "mix task" do
    setup do
      {:ok, indexable_data()}
    end

    test "mix elasticsearch.build", %{count: count} do
      with index <- Config.elasticsearch_index() do
        assert indexed_doc_count() == 0

        [to_string(index), "--cluster", "Meadow.ElasticsearchCluster"]
        |> BuildTask.run()

        Elasticsearch.Index.refresh(Meadow.ElasticsearchCluster, index)
        assert indexed_doc_count() == count
      end
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
      Indexer.reindex_all!()
      assert_receive {:api_request, report_1}, 2500
      assert_receive {:api_request, report_2}, 2500

      assert [report_1, report_2]
             |> Enum.all?(&(get_in(&1, ["error", "class"]) == "Meadow.IndexerError"))
    end

    test "hot swap errors reported to Honeybadger" do
      restart_with_config(exclude_envs: [])
      assert {:error, _} = Indexer.hot_swap()
      assert_receive {:api_request, report_1}, 2500
      assert_receive {:api_request, report_2}, 2500

      assert [report_1, report_2]
             |> Enum.all?(&(get_in(&1, ["error", "class"]) == "Elasticsearch.Exception"))
    end
  end
end
