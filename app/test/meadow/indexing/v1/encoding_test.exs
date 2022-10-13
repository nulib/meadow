defmodule Meadow.Indexing.V1.EncodingTest do
  use Meadow.AuthorityCase
  use Meadow.DataCase
  use Meadow.IndexCase

  alias Meadow.Config
  alias Meadow.Data.{CodedTerms, FileSets, Indexer, Works}
  alias Meadow.Data.Schemas.{Collection, FileSet, Work}
  alias Meadow.Search.Document

  describe "encoding" do
    setup do
      with %{collection: collection, works: works, file_sets: file_sets} <- indexable_data() do
        {:ok,
         %{
           collection: collection |> Repo.preload(Collection.required_index_preloads()),
           work: List.first(works) |> Repo.preload(Work.required_index_preloads()),
           file_set: List.first(file_sets) |> Repo.preload(FileSet.required_index_preloads())
         }}
      end
    end

    test "collection encoding", %{collection: subject} do
      doc = subject |> Document.encode(1)
      assert doc |> get_in([:model, :application]) == "Meadow"
      assert doc |> get_in([:model, :name]) == "Collection"
      assert doc |> get_in([:title]) == subject.title
    end

    test "work encoding", %{work: subject} do
      doc = subject |> Document.encode(1)

      assert doc |> get_in([:model, :application]) == "Meadow"
      assert doc |> get_in([:model, :name]) == "Work"
      assert doc |> get_in([:fileSets]) |> length == 2

      with metadata <- subject.descriptive_metadata do
        assert doc |> get_in([:descriptiveMetadata, :title]) ==
                 metadata.title
      end

      with metadata <- subject.administrative_metadata do
        assert doc |> get_in([:administrativeMetadata, :projectName]) == metadata.project_name
      end
    end

    test "work encodes thumbnail field", %{work: subject} do
      doc = subject |> Document.encode(1)
      assert is_nil(doc |> get_in([:thumbnail]))

      file_set = subject.file_sets |> Enum.at(1)
      derivatives = FileSets.add_derivative(file_set, :poster, FileSets.poster_uri_for(file_set))
      {:ok, file_set} = FileSets.update_file_set(file_set, %{derivatives: derivatives})
      {:ok, subject} = Works.set_representative_image(subject, file_set)

      Indexer.synchronize_index()
      doc = subject |> Document.encode(1)

      assert doc |> get_in([:thumbnail]) ==
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
      doc = subject |> Document.encode(1)
      assert doc |> get_in([:title]) == subject.descriptive_metadata.title
      assert doc |> get_in([:alternateTitle]) == subject.descriptive_metadata.alternate_title
      assert doc |> get_in([:collectionTitle]) == subject.collection.title

      creators =
        Enum.map(subject.descriptive_metadata.creator, fn creator -> creator.term.label end)

      assert doc |> get_in([:creator]) == creators

      contributors =
        Enum.map(subject.descriptive_metadata.contributor, fn contributor ->
          contributor.term.label <>
            " (" <> CodedTerms.label(contributor.role.id, "marc_relator") <> ")"
        end)

      assert doc |> get_in([:contributor]) == contributors

      subjects = Enum.map(subject.descriptive_metadata.subject, fn s -> s.term.label end)

      assert doc |> get_in([:subject]) == subjects

      dates = Enum.map(subject.descriptive_metadata.date_created, fn d -> d.humanized end)

      assert doc |> get_in([:dateCreated]) == dates
    end

    test "work encodes controlled term variants", %{work: subject} do
      {:ok, subject} =
        subject
        |> Works.update_work(%{
          descriptive_metadata: %{
            subject: [
              %{
                role: %{id: "TOPICAL", scheme: "subject_role"},
                term: %{id: "http://id.loc.gov/authorities/names/nb2015010626"}
              }
            ]
          }
        })

      Indexer.synchronize_index()
      doc = subject |> Document.encode(1)

      assert doc
             |> get_in([:descriptiveMetadata, :subject, Access.at(0), :term, :variants])
             |> Enum.member?("BCT G.B. (Border Collie Trust G.B.)")
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

      doc = subject |> Document.encode(1)
      assert doc |> get_in([:model, :application]) == "Meadow"
      assert doc |> get_in([:model, :name]) == "FileSet"
      assert doc |> get_in([:description]) == subject.core_metadata.description
      assert doc |> get_in([:digests]) == subject.core_metadata.digests
      assert doc |> get_in([:label]) == subject.core_metadata.label
      assert doc |> get_in([:posterOffset]) == 100
      assert doc |> get_in([:webvtt]) == subject.structural_metadata.value
      assert doc |> get_in([:rank]) == subject.rank

      assert doc |> get_in([:streamingUrl]) == Path.join(Config.streaming_url(), "bar.m3u8")

      poster_url =
        with uri <- URI.parse(Config.iiif_server_url()) do
          uri
          |> URI.merge("posters/#{subject.id}")
          |> URI.to_string()
        end

      assert doc |> get_in([:representativeImageUrl]) == poster_url
    end

    test "file set encoding with bad EXIF data (empty string)", %{file_set: subject} do
      {:ok, subject} =
        subject
        |> FileSets.update_file_set(%{
          extracted_metadata: %{exif: ""}
        })

      subject = FileSets.get_file_set_with_work_and_sheet!(subject.id)

      doc = subject |> Document.encode(1)
      assert doc |> get_in([:extractedMetadata]) == %{"exif" => %{}}
    end
  end
end
