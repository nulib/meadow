defmodule Meadow.Legacy.ViewsTest do
  @moduledoc false
  use Meadow.DataCase
  use Meadow.AuthorityCase

  alias Meadow.Repo

  defp legacy_work(id) do
    %{rows: [[row]]} =
      Repo.query!("SELECT to_jsonb(v) FROM legacy_works v WHERE v.id = $1", [Ecto.UUID.dump!(id)])

    row
  end

  defp legacy_file_set(id) do
    %{rows: [[row]]} =
      Repo.query!("SELECT to_jsonb(v) FROM legacy_file_sets v WHERE v.id = $1", [
        Ecto.UUID.dump!(id)
      ])

    row
  end

  describe "legacy_works" do
    setup do
      work =
        work_fixture(%{
          descriptive_metadata: %{
            title: "A Title",
            abstract: ["one", "two"],
            subject: [
              %{term: "http://id.loc.gov/authorities/names/nb2015010626", role: %{id: "TOPICAL", scheme: "subject_role"}}
            ],
            notes: [%{note: "A note", type: %{id: "GENERAL_NOTE", scheme: "note_type"}}],
            date_created: ["1975-07-01"]
          }
        })

      {:ok, work: work, legacy: legacy_work(work.id)}
    end

    test "scalars and repeating free text come back as they were stored in jsonb", %{
      legacy: legacy
    } do
      descriptive = legacy["descriptive_metadata"]

      assert descriptive["title"] == "A Title"
      assert descriptive["abstract"] == ["one", "two"]
      # a field with no values is an empty list, as the embed defaulted to
      assert descriptive["box_name"] == []
    end

    test "coded terms are `{id, scheme}` objects again", %{legacy: legacy} do
      assert %{"id" => _, "scheme" => "visibility"} = legacy["visibility"]
    end

    test "controlled entries carry a bare term uri and a coded role", %{legacy: legacy} do
      assert [%{"term" => "http://id.loc.gov/authorities/names/nb2015010626", "role" => role}] =
               legacy["descriptive_metadata"]["subject"]

      assert role == %{"id" => "TOPICAL", "scheme" => "subject_role"}
    end

    test "controlled fields with no entries default to an empty list", %{legacy: legacy} do
      assert legacy["descriptive_metadata"]["genre"] == []
    end

    test "notes carry their coded type", %{legacy: legacy} do
      assert [%{"note" => "A note", "type" => %{"id" => "GENERAL_NOTE", "scheme" => "note_type"}}] =
               legacy["descriptive_metadata"]["notes"]
    end

    test "dates carry edtf only, since humanized has no SQL equivalent", %{legacy: legacy} do
      assert [%{"edtf" => "1975-07-01"}] = legacy["descriptive_metadata"]["date_created"]
    end

    test "administrative metadata is rebuilt too", %{legacy: legacy} do
      assert is_map(legacy["administrative_metadata"])
      assert Map.has_key?(legacy["administrative_metadata"], "project_name")
    end
  end

  describe "legacy_file_sets" do
    setup do
      work = work_fixture()
      file_set = file_set_fixture(%{work_id: work.id})
      {:ok, file_set: file_set, legacy: legacy_file_set(file_set.id)}
    end

    test "core metadata is rebuilt with nested digests", %{legacy: legacy, file_set: file_set} do
      core = legacy["core_metadata"]

      assert core["location"] == file_set.core_metadata.location
      assert core["original_filename"] == file_set.core_metadata.original_filename

      digests = file_set.core_metadata |> Map.get(:digest_sha256)
      if digests do
        assert core["digests"]["sha256"] == digests
      end
    end

    test "role is a coded term object", %{legacy: legacy} do
      assert %{"scheme" => "file_set_role"} = legacy["role"]
    end

    test "derivatives and extracted metadata default to empty objects", %{legacy: legacy} do
      assert is_map(legacy["derivatives"])
      assert is_map(legacy["extracted_metadata"])
    end
  end

  describe "legacy_extracted_document/1" do
    test "rebuilds an arbitrarily nested tool document from the flattened rows" do
      work = work_fixture()
      file_set = file_set_fixture(%{work_id: work.id})

      meta_id = Ecto.UUID.generate()

      Repo.query!(
        "INSERT INTO file_set_extracted_metadata (id, file_set_id, tool, tool_version) VALUES ($1, $2, 'exif', '12.60')",
        [Ecto.UUID.dump!(meta_id), Ecto.UUID.dump!(file_set.id)]
      )

      # path, value_type, value — exactly what the backfill's flatten/2 produces
      rows = [
        {[], "object", nil},
        {["value"], "object", nil},
        {["value", "ImageWidth"], "integer", "4000"},
        {["value", "Flash"], "boolean", "false"},
        {["value", "Artist"], "null", nil},
        {["value", "Tags"], "array", nil},
        {["value", "Tags", "0"], "string", "a"},
        {["value", "Tags", "1"], "string", "b"}
      ]

      Enum.each(rows, fn {path, type, value} ->
        Repo.query!(
          "INSERT INTO file_set_extracted_metadata_entries (id, extracted_metadata_id, path, value_type, value) VALUES (gen_random_uuid(), $1, $2, $3, $4)",
          [Ecto.UUID.dump!(meta_id), path, type, value]
        )
      end)

      %{rows: [[document]]} =
        Repo.query!("SELECT legacy_extracted_document($1)", [Ecto.UUID.dump!(meta_id)])

      assert document == %{
               "value" => %{
                 "ImageWidth" => 4000,
                 "Flash" => false,
                 "Artist" => nil,
                 "Tags" => ["a", "b"]
               }
             }
    end
  end
end
