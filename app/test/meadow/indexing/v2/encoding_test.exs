defmodule Meadow.Indexing.V2.EncodingTest do
  use Meadow.AuthorityCase
  use Meadow.DataCase
  use Meadow.IndexCase

  alias Meadow.Config
  alias Meadow.AI.Provenance
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
      doc = subject |> Document.encode(2)
      assert doc |> get_in([:api_model]) == "Collection"
      assert doc |> get_in([:title]) == subject.title
    end

    test "work encoding", %{work: subject} do
      doc = subject |> Document.encode(2)

      assert doc |> get_in([:api_model]) == "Work"
      assert doc |> get_in([:file_sets]) |> length == 2

      with metadata <- subject.descriptive_metadata do
        assert doc |> get_in([:title]) ==
                 metadata.title
      end
    end

    test "work encodes compact AI provenance", %{work: subject} do
      {:ok, activity} =
        Provenance.create_activity(%{
          activity_type: "metadata_direct_apply",
          model: "test-model",
          work_id: subject.id,
          status: "completed"
        })

      {:ok, _target} =
        Provenance.record_target(
          activity,
          %{
            target_type: "Work",
            target_id: subject.id,
            field_path: "descriptive_metadata.description",
            operation: "replace",
            proposed_value: ["Description"],
            origin: "ai_generated",
            status: "applied"
          },
          "applied"
        )

      doc = subject |> Document.encode(2)

      assert %{
               origin: "ai_generated",
               model: "test-model",
               activity_id: activity_id
             } = doc |> get_in([:ai_provenance, "descriptive_metadata.description"])

      assert activity_id == activity.id
    end

    test "indexes a work with AI provenance without bulk mapping errors", %{work: subject} do
      {:ok, activity} =
        Provenance.create_activity(%{
          activity_type: "metadata_direct_apply",
          model: "test-model",
          work_id: subject.id,
          status: "completed"
        })

      {:ok, _target} =
        Provenance.record_target(
          activity,
          %{
            target_type: "Work",
            target_id: subject.id,
            field_path: "descriptive_metadata.description",
            operation: "replace",
            proposed_value: ["Description"],
            origin: "ai_generated",
            status: "applied"
          },
          "applied"
        )

      log =
        ExUnit.CaptureLog.capture_log(fn ->
          Indexer.synchronize_index()
        end)

      refute log =~ "Bulk upload encountered errors"

      source = indexed_doc(Work, 2, subject.id)

      assert get_in(source, ["ai_provenance", "descriptive_metadata.description", "origin"]) ==
               "ai_generated"
    end

    test "work encodes nav_place", %{work: subject} do
      nav_place = [
        %{
          "label" => "Calcutta",
          "coordinates" => [88.3639, 22.5726]
        }
      ]

      {:ok, subject} =
        subject
        |> Works.update_work(%{
          descriptive_metadata: %{
            nav_place: nav_place
          }
        })

      doc = subject |> Document.encode(2)
      assert doc |> get_in([:nav_place]) == nav_place
    end

    test "work encodes thumbnail field", %{work: subject} do
      Indexer.synchronize_index()
      doc = subject |> Document.encode(2)

      assert doc |> get_in([:thumbnail]) |> URI.parse() |> Map.get(:path) ==
               "/works/#{subject.id}/thumbnail"
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
      doc = subject |> Document.encode(2)
      assert doc |> get_in([:title]) == subject.descriptive_metadata.title
      # Repeating free-text fields are stored as identified ValueEntry embeds but
      # flattened back to plain strings in the index document.
      assert doc |> get_in([:alternate_title]) ==
               Enum.map(subject.descriptive_metadata.alternate_title, & &1.value)
      assert doc |> get_in([:collection, :title]) == subject.collection.title

      creators =
        Enum.map(subject.descriptive_metadata.creator, fn creator -> creator.term.label end)

      assert doc |> get_in([:creator]) |> Enum.map(& &1.label) == creators

      contributors =
        Enum.map(subject.descriptive_metadata.contributor, fn contributor ->
          contributor.term.label <>
            " (" <> CodedTerms.label(contributor.role.id, "marc_relator") <> ")"
        end)

      assert doc |> get_in([:contributor]) |> Enum.map(& &1.label_with_role) == contributors

      subjects = Enum.map(subject.descriptive_metadata.subject, fn s -> s.term.label end)

      assert doc |> get_in([:subject]) |> Enum.map(& &1.label) == subjects

      dates = Enum.map(subject.descriptive_metadata.date_created, fn d -> d.humanized end)

      assert doc |> get_in([:date_created]) == dates
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
      doc = subject |> Document.encode(2)

      assert doc
             |> get_in([:subject, Access.at(0), :variants])
             |> Enum.member?("BCT G.B. (Border Collie Trust G.B.)")
    end

    test "file set encoding", %{file_set: subject} do
      derivatives = FileSets.add_derivative(subject, :poster, FileSets.poster_uri_for(subject))

      {:ok, subject} =
        subject
        |> FileSets.update_file_set(%{derivatives: derivatives, poster_offset: 100})

      subject = FileSets.get_file_set_with_work_and_sheet!(subject.id)

      doc = subject |> Document.encode(2)
      assert doc |> get_in([:api_model]) == "FileSet"
      assert doc |> get_in([:description]) == subject.core_metadata.description
      assert doc |> get_in([:digests]) == subject.core_metadata.digests
      assert doc |> get_in([:label]) == subject.core_metadata.label
      assert doc |> get_in([:poster_offset]) == 100
      assert doc |> get_in([:rank]) == subject.rank
      assert doc |> get_in([:width]) |> is_nil()
      assert doc |> get_in([:height]) |> is_nil()

      assert doc |> get_in([:streaming_url]) == Path.join(Config.streaming_url(), "bar.m3u8")

      poster_url =
        with uri <- URI.parse(Config.iiif_server_url()) do
          uri
          |> URI.merge("posters/#{subject.id}")
          |> URI.to_string()
        end

      assert doc |> get_in([:representative_image_url]) == poster_url
    end

    test "file set encoding with bad EXIF data (empty string)", %{file_set: subject} do
      {:ok, subject} =
        subject
        |> FileSets.update_file_set(%{
          extracted_metadata: %{exif: ""}
        })

      subject = FileSets.get_file_set_with_work_and_sheet!(subject.id)

      doc = subject |> Document.encode(2)
      assert doc |> get_in([:extracted_metadata]) == %{"exif" => %{}}
    end
  end
end
