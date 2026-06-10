defmodule Meadow.ArchivesSpace.MapperTest do
  use ExUnit.Case, async: true

  alias Meadow.ArchivesSpace.Mapper
  alias Meadow.Data.Schemas.{ControlledMetadataEntry, Work, WorkDescriptiveMetadata}

  @digital_object_uri "/repositories/2/digital_objects/77"

  defp work(descriptive \\ %{}, attrs \\ %{}) do
    descriptive =
      Map.merge(
        %{title: "A Work", description: [], abstract: [], subject: []},
        descriptive
      )

    %Work{
      id: "01dz7teav-test-work-id",
      published: false,
      visibility: %{id: "OPEN", scheme: "visibility", label: "Public"},
      descriptive_metadata: struct!(WorkDescriptiveMetadata, descriptive)
    }
    |> struct!(attrs)
  end

  defp subject_entry(id, label, role \\ "TOPICAL") do
    %ControlledMetadataEntry{
      role: %{id: role, scheme: "subject_role", label: nil},
      term: %{id: id, label: label}
    }
  end

  defp entry(id, label, role \\ nil) do
    %ControlledMetadataEntry{role: role, term: %{id: id, label: label}}
  end

  defp archival_object(attrs \\ %{}) do
    Map.merge(
      %{
        "jsonmodel_type" => "archival_object",
        "uri" => "/repositories/2/archival_objects/1",
        "lock_version" => 3,
        "title" => "Original Title",
        "notes" => [],
        "subjects" => [],
        "instances" => []
      },
      attrs
    )
  end

  describe "apply_work/4" do
    test "replaces the title and preserves the lock_version" do
      result = Mapper.apply_work(archival_object(), work())

      assert result["title"] == "A Work"
      assert result["lock_version"] == 3
    end

    test "leaves the title alone when the work has none" do
      result = Mapper.apply_work(archival_object(), work(%{title: nil}))
      assert result["title"] == "Original Title"
    end

    test "writes Meadow-labeled notes and preserves foreign notes" do
      archivist_note = %{
        "jsonmodel_type" => "note_multipart",
        "type" => "scopecontent",
        "label" => "Processing note",
        "subnotes" => [%{"content" => "written by an archivist"}]
      }

      stale_meadow_note = %{
        "jsonmodel_type" => "note_singlepart",
        "type" => "abstract",
        "label" => Mapper.note_label(),
        "content" => ["stale abstract"]
      }

      result =
        archival_object(%{"notes" => [archivist_note, stale_meadow_note]})
        |> Mapper.apply_work(
          work(%{description: ["First paragraph", "Second paragraph"], abstract: ["An abstract"]})
        )

      assert archivist_note in result["notes"]
      refute stale_meadow_note in result["notes"]

      meadow_notes = Enum.filter(result["notes"], &(&1["label"] == Mapper.note_label()))
      assert [scope, abstract] = meadow_notes
      assert scope["type"] == "scopecontent"
      assert Enum.map(scope["subnotes"], & &1["content"]) == ["First paragraph", "Second paragraph"]
      assert abstract["content"] == ["An abstract"]
    end

    test "omits notes for empty fields" do
      result = Mapper.apply_work(archival_object(), work())
      assert result["notes"] == []
    end

    test "merges subject refs without duplicating" do
      result =
        archival_object(%{"subjects" => [%{"ref" => "/subjects/1"}]})
        |> Mapper.apply_work(work(), subject_refs: ["/subjects/1", "/subjects/2"])

      assert result["subjects"] == [%{"ref" => "/subjects/1"}, %{"ref" => "/subjects/2"}]
    end

    test "adds a digital object instance exactly once" do
      result = Mapper.apply_work(archival_object(), work(), digital_object_uri: @digital_object_uri)

      assert [instance] = result["instances"]
      assert instance["instance_type"] == "digital_object"
      assert instance["digital_object"]["ref"] == @digital_object_uri

      assert Mapper.apply_work(result, work(), digital_object_uri: @digital_object_uri)["instances"] ==
               [instance]
    end

    test "adds no instance without a digital object uri" do
      assert Mapper.apply_work(archival_object(), work())["instances"] == []
    end
  end

  describe "subject/1" do
    test "builds a subject record with a derived source" do
      assert %{
               "jsonmodel_type" => "subject",
               "source" => "lcsh",
               "authority_id" => "http://id.loc.gov/authorities/subjects/sh85070610",
               "terms" => [%{"term" => "Subject Label", "term_type" => "topical"}]
             } =
               subject_entry("http://id.loc.gov/authorities/subjects/sh85070610", "Subject Label")
               |> Mapper.subject()
    end

    test "maps subject roles to term types" do
      geographic = subject_entry("https://sws.geonames.org/4299276/", "Kentucky", "GEOGRAPHICAL")

      assert %{"source" => "local", "terms" => [%{"term_type" => "geographic"}]} =
               Mapper.subject(geographic)

      temporal = subject_entry("http://example.org/temporal/1", "1920s", "TEMPORAL")
      assert %{"source" => "local", "terms" => [%{"term_type" => "temporal"}]} = Mapper.subject(temporal)
    end

    test "returns nil for entries without a term URI" do
      assert %ControlledMetadataEntry{term: %{id: nil, label: "No URI"}} |> Mapper.subject() |> is_nil()
    end
  end

  describe "digital_object/2" do
    test "builds a digital object pointing at Digital Collections" do
      result = work() |> Mapper.digital_object()

      assert result["jsonmodel_type"] == "digital_object"
      assert result["digital_object_id"] == "01dz7teav-test-work-id"
      assert result["title"] == "A Work"

      assert [%{"file_uri" => file_uri, "publish" => true}] = result["file_versions"]
      assert file_uri == Mapper.digital_collections_url(work())
      assert file_uri =~ "items/01dz7teav-test-work-id"
    end

    test "publishes only published, non-private works" do
      refute work() |> Mapper.digital_object() |> Map.get("publish")

      assert work(%{}, %{published: true}) |> Mapper.digital_object() |> Map.get("publish")

      restricted = %{id: "RESTRICTED", scheme: "visibility", label: "Private"}

      refute work(%{}, %{published: true, visibility: restricted})
             |> Mapper.digital_object()
             |> Map.get("publish")
    end

    test "preserves the identifier and lock_version of an existing record" do
      existing = %{"lock_version" => 9, "digital_object_id" => "legacy-id"}

      result = work(%{}, %{published: true}) |> Mapper.digital_object(existing)

      assert result["lock_version"] == 9
      assert result["digital_object_id"] == "legacy-id"
      assert result["title"] == "A Work"
    end
  end

  describe "broadened metadata in apply_work/3" do
    test "adds a userestrict note from rights statement and terms of use" do
      result =
        Mapper.apply_work(
          archival_object(),
          work(%{
            rights_statement: %{id: "http://rightsstatements.org/vocab/InC/1.0/", label: "In Copyright"},
            terms_of_use: "Ask first"
          })
        )

      assert [note] = Enum.filter(result["notes"], &(&1["type"] == "userestrict"))
      assert note["label"] == Mapper.note_label()
      contents = Enum.map(note["subnotes"], & &1["content"])
      assert "In Copyright (http://rightsstatements.org/vocab/InC/1.0/)" in contents
      assert "Ask first" in contents
    end

    test "merges linked agents by ref, preserving archivist agents" do
      archivist_agent = %{"ref" => "/agents/people/999", "role" => "creator"}
      meadow_agent = %{"ref" => "/agents/people/1", "role" => "creator", "relator" => "pht"}

      result =
        archival_object(%{"linked_agents" => [archivist_agent]})
        |> Mapper.apply_work(work(), linked_agents: [meadow_agent])

      assert archivist_agent in result["linked_agents"]
      assert meadow_agent in result["linked_agents"]
      # idempotent: re-applying does not duplicate Meadow's agent
      reapplied = Mapper.apply_work(result, work(), linked_agents: [meadow_agent])
      assert Enum.count(reapplied["linked_agents"], &(&1["ref"] == "/agents/people/1")) == 1
    end

    test "adds creation dates and preserves foreign dates" do
      archivist_date = %{"jsonmodel_type" => "date", "label" => "digitized", "expression" => "2001"}

      result =
        archival_object(%{"dates" => [archivist_date]})
        |> Mapper.apply_work(work(%{date_created: [%{edtf: "1965", humanized: "1965"}]}))

      assert archivist_date in result["dates"]
      assert [creation] = Enum.filter(result["dates"], &(&1["label"] == "creation"))
      assert creation["expression"] == "1965"
      assert creation["begin"] == "1965"
    end

    test "adds lang_materials from language URIs and preserves foreign ones" do
      archivist_lang = %{
        "jsonmodel_type" => "lang_material",
        "language_and_script" => %{"language" => "fre"}
      }

      result =
        archival_object(%{"lang_materials" => [archivist_lang]})
        |> Mapper.apply_work(
          work(%{
            language: [entry("http://id.loc.gov/vocabulary/languages/eng", "English")]
          })
        )

      languages = Enum.map(result["lang_materials"], &get_in(&1, ["language_and_script", "language"]))
      assert "fre" in languages
      assert "eng" in languages
    end
  end

  describe "agent/1" do
    test "builds a person agent by default with a derived source" do
      assert {record, "/agents/people"} =
               entry("http://id.loc.gov/authorities/names/n79021164", "Twain, Mark")
               |> Mapper.agent()

      assert record["jsonmodel_type"] == "agent_person"
      assert [name] = record["names"]
      assert name["primary_name"] == "Twain, Mark"
      assert name["source"] == "naf"
      assert name["authority_id"] == "http://id.loc.gov/authorities/names/n79021164"
    end

    test "builds a corporate agent for corporate authority URIs" do
      assert {record, "/agents/corporate_entities"} =
               entry("https://example.org/corporate/acme", "ACME Corp")
               |> Mapper.agent()

      assert record["jsonmodel_type"] == "agent_corporate_entity"
      assert [%{"jsonmodel_type" => "name_corporate_entity"}] = record["names"]
    end

    test "returns nil without a term URI" do
      assert entry(nil, "No URI") |> Mapper.agent() |> is_nil()
    end
  end

  describe "linked_agent/2" do
    test "carries a contributor's MARC relator, lowercased" do
      contributor = entry("/x", "Photog", %{id: "PHT", scheme: "marc_relator", label: nil})
      assert %{"ref" => "/agents/people/1", "role" => "creator", "relator" => "pht"} =
               Mapper.linked_agent("/agents/people/1", contributor)
    end

    test "omits relator for a creator" do
      creator = entry("/x", "Maker")
      refute Mapper.linked_agent("/agents/people/1", creator) |> Map.has_key?("relator")
    end
  end

  describe "genre_subject/1" do
    test "builds a genre_form subject" do
      assert %{"terms" => [%{"term_type" => "genre_form", "term" => "Posters"}]} =
               entry("http://vocab.getty.edu/aat/300027221", "Posters") |> Mapper.genre_subject()
    end
  end

  describe "digital_object_component/2" do
    test "builds a component with an image file_version and a transcription note" do
      component = %{
        file_set_id: "abc-123",
        position: 0,
        label: "Page 1",
        image_uri: "https://iiif.example.edu/abc-123",
        transcription: "Dear John"
      }

      result = Mapper.digital_object_component(component, @digital_object_uri)

      assert result["jsonmodel_type"] == "digital_object_component"
      assert result["component_id"] == "abc-123"
      assert result["label"] == "Page 1"
      assert result["position"] == 0
      assert result["digital_object"]["ref"] == @digital_object_uri
      assert [%{"use_statement" => "image-service", "file_uri" => uri}] = result["file_versions"]
      assert uri == "https://iiif.example.edu/abc-123"
      assert [note] = result["notes"]
      assert note["jsonmodel_type"] == "note_digital_object"
      assert note["label"] == Mapper.note_label()
      assert note["content"] == ["Dear John"]
    end

    test "omits the file_version and note when image/transcription are absent" do
      component = %{file_set_id: "abc-123", position: 1, label: "Page 2", image_uri: nil, transcription: nil}
      result = Mapper.digital_object_component(component, @digital_object_uri)
      assert result["file_versions"] == []
      assert result["notes"] == []
    end
  end

  describe "apply_component/2" do
    test "replaces only the Meadow note and preserves uri, lock_version, archivist notes" do
      archivist_note = %{"jsonmodel_type" => "note_digital_object", "type" => "note", "label" => "By hand", "content" => ["keep me"]}
      stale_meadow_note = %{"jsonmodel_type" => "note_digital_object", "type" => "note", "label" => Mapper.note_label(), "content" => ["old"]}

      existing = %{
        "uri" => "/repositories/2/digital_object_components/5",
        "lock_version" => 7,
        "label" => "Old Label",
        "notes" => [archivist_note, stale_meadow_note]
      }

      desired =
        Mapper.digital_object_component(
          %{file_set_id: "abc-123", position: 0, label: "New Label", image_uri: nil, transcription: "fresh"},
          @digital_object_uri
        )

      result = Mapper.apply_component(existing, desired)

      assert result["uri"] == "/repositories/2/digital_object_components/5"
      assert result["lock_version"] == 7
      assert result["label"] == "New Label"
      assert archivist_note in result["notes"]
      refute stale_meadow_note in result["notes"]
      assert [%{"content" => ["fresh"]}] = Enum.filter(result["notes"], &(&1["label"] == Mapper.note_label()))
    end
  end
end
