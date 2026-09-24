defmodule Meadow.Data.Schemas.MetadataSchemaTest do
  @moduledoc false
  use Meadow.DataCase

  alias Meadow.Data.Schemas.{
    ControlledMetadataEntry,
    DateCreatedEntry,
    MetadataSchema,
    MetadataValue,
    NavPlaceEntry,
    NoteEntry,
    RelatedURLEntry,
    WorkAdministrativeMetadata,
    WorkDescriptiveMetadata
  }

  describe "reflection" do
    test "fields are reported in declaration order" do
      assert WorkAdministrativeMetadata.__metadata__(:fields) == [
               :library_unit,
               :preservation_level,
               :status,
               :project_cycle,
               :project_name,
               :project_desc,
               :project_proposer,
               :project_manager,
               :project_task_number
             ]

      assert WorkDescriptiveMetadata.__metadata__(:fields) |> Enum.take(4) ==
               [:title, :terms_of_use, :license, :rights_statement]
    end

    test "section" do
      assert WorkDescriptiveMetadata.__metadata__(:section) == "descriptive"
      assert WorkAdministrativeMetadata.__metadata__(:section) == "administrative"
    end

    test "fields by kind" do
      assert WorkDescriptiveMetadata.__metadata__(:fields, :string) == [:title, :terms_of_use]

      assert WorkDescriptiveMetadata.__metadata__(:fields, :coded) == [
               :license,
               :rights_statement
             ]

      assert :abstract in WorkDescriptiveMetadata.__metadata__(:fields, :values)
      refute :title in WorkDescriptiveMetadata.__metadata__(:fields, :values)

      assert WorkDescriptiveMetadata.__metadata__(:fields, :controlled) ==
               ~w(contributor creator genre language location style_period subject technique)a

      assert WorkDescriptiveMetadata.__metadata__(:fields, :entries) ==
               [:date_created, :notes, :related_url, :nav_place]

      assert WorkDescriptiveMetadata.__metadata__(:fields, {:entries, DateCreatedEntry}) ==
               [:date_created]

      assert WorkAdministrativeMetadata.__metadata__(:fields, :entries) == []
    end

    test "kind, options and schema of a field" do
      assert WorkDescriptiveMetadata.__metadata__(:kind, :title) == :string
      assert WorkDescriptiveMetadata.__metadata__(:kind, :license) == :coded
      assert WorkDescriptiveMetadata.__metadata__(:kind, :abstract) == :values
      assert WorkDescriptiveMetadata.__metadata__(:kind, :creator) == :controlled
      assert WorkDescriptiveMetadata.__metadata__(:kind, :notes) == :entries
      assert WorkDescriptiveMetadata.__metadata__(:kind, :nope) == nil

      assert WorkDescriptiveMetadata.__metadata__(:options, :contributor) == [role_required: true]
      assert WorkDescriptiveMetadata.__metadata__(:options, :creator) == []
      assert WorkDescriptiveMetadata.__metadata__(:options, :nope) == nil

      assert WorkDescriptiveMetadata.__metadata__(:schema, :title) == nil
      assert WorkDescriptiveMetadata.__metadata__(:schema, :abstract) == MetadataValue
      assert WorkDescriptiveMetadata.__metadata__(:schema, :creator) == ControlledMetadataEntry
      assert WorkDescriptiveMetadata.__metadata__(:schema, :notes) == NoteEntry
      assert WorkDescriptiveMetadata.__metadata__(:schema, :related_url) == RelatedURLEntry
      assert WorkDescriptiveMetadata.__metadata__(:schema, :nav_place) == NavPlaceEntry
      assert WorkDescriptiveMetadata.__metadata__(:schema, :nope) == nil
    end

    test "permitted and repeating partition the fields" do
      all = WorkDescriptiveMetadata.__metadata__(:fields)
      permitted = WorkDescriptiveMetadata.permitted()
      repeating = WorkDescriptiveMetadata.repeating_fields()

      assert permitted == WorkDescriptiveMetadata.__metadata__(:permitted)
      assert repeating == WorkDescriptiveMetadata.__metadata__(:repeating)
      assert permitted == [:title, :terms_of_use, :license, :rights_statement]
      assert Enum.sort(permitted ++ repeating) == Enum.sort(all)
      assert permitted -- WorkDescriptiveMetadata.__schema__(:fields) == []
      assert repeating -- WorkDescriptiveMetadata.__schema__(:associations) == []
    end

    test "field_names covers every declared field" do
      for module <- [WorkDescriptiveMetadata, WorkAdministrativeMetadata] do
        assert Enum.sort(module.field_names()) == Enum.sort(module.__metadata__(:fields))
      end
    end
  end

  describe "generated Ecto schema" do
    test "string and coded fields are columns" do
      assert WorkDescriptiveMetadata.__schema__(:type, :title) == :string

      assert {:parameterized, {Meadow.Data.Types.CodedTerm, %{scheme: "license"}}} =
               WorkDescriptiveMetadata.__schema__(:type, :license)

      assert WorkDescriptiveMetadata.__schema__(:field_source, :license) == :license_id
      assert WorkAdministrativeMetadata.__schema__(:field_source, :status) == :status_id
    end

    test "values fields are has_many MetadataValue filtered to section and field" do
      assert %Ecto.Association.Has{
               related: MetadataValue,
               owner_key: :work_id,
               related_key: :work_id,
               where: [section: "administrative", field: "project_name"],
               defaults: [section: "administrative", field: "project_name"],
               preload_order: [asc: :position],
               on_replace: :delete
             } = WorkAdministrativeMetadata.__schema__(:association, :project_name)
    end

    test "controlled fields are has_many ControlledMetadataEntry filtered to field" do
      assert %Ecto.Association.Has{
               related: ControlledMetadataEntry,
               where: [field: "creator"],
               defaults: [field: "creator"],
               preload_order: [asc: :position],
               on_replace: :delete
             } = WorkDescriptiveMetadata.__schema__(:association, :creator)
    end

    test "entries fields are has_many of their schema" do
      assert %Ecto.Association.Has{
               related: NoteEntry,
               owner_key: :work_id,
               related_key: :work_id,
               where: [],
               preload_order: [asc: :position],
               on_replace: :delete
             } = WorkDescriptiveMetadata.__schema__(:association, :notes)
    end

    test "work is the primary key" do
      assert WorkDescriptiveMetadata.__schema__(:primary_key) == [:work_id]

      assert %Ecto.Association.BelongsTo{} =
               WorkDescriptiveMetadata.__schema__(:association, :work)
    end
  end

  describe "changeset/2" do
    test "casts columns, values, controlled and entries fields" do
      changeset =
        WorkDescriptiveMetadata.changeset(%WorkDescriptiveMetadata{}, %{
          title: "Title",
          license: %{id: "http://www.europeana.eu/portal/rights/rr-r.html", scheme: "license"},
          abstract: ["one", %{value: "two"}],
          date_created: ["1999", %{edtf: "2000"}],
          notes: [%{note: "a note", type: %{id: "GENERAL_NOTE", scheme: "note_type"}}]
        })

      assert changeset.valid?, inspect(changeset.errors)
      assert Ecto.Changeset.get_change(changeset, :title) == "Title"

      assert changeset
             |> Ecto.Changeset.get_change(:abstract)
             |> Enum.map(&Ecto.Changeset.get_change(&1, :value)) == ["one", "two"]

      assert changeset
             |> Ecto.Changeset.get_change(:abstract)
             |> Enum.map(&Ecto.Changeset.get_change(&1, :position)) == [0, 1]

      assert changeset
             |> Ecto.Changeset.get_change(:date_created)
             |> Enum.map(&Ecto.Changeset.get_change(&1, :edtf)) == ["1999", "2000"]

      assert [note] = Ecto.Changeset.get_change(changeset, :notes)
      assert Ecto.Changeset.get_change(note, :note) == "a note"
    end

    test "only declared columns are permitted" do
      changeset =
        WorkAdministrativeMetadata.changeset(%WorkAdministrativeMetadata{}, %{
          project_cycle: "2024",
          bogus: "x"
        })

      assert changeset.valid?
      assert changeset.changes == %{project_cycle: "2024"}
    end

    test "role_required controlled fields reject entries without a role" do
      term = %{id: "http://id.loc.gov/authorities/names/n79091588"}

      changeset =
        WorkDescriptiveMetadata.changeset(%WorkDescriptiveMetadata{}, %{
          contributor: [%{term: term}],
          creator: [%{term: term}]
        })

      refute changeset.valid?
      assert [contributor_changeset] = Ecto.Changeset.get_change(changeset, :contributor)
      assert Keyword.has_key?(contributor_changeset.errors, :role)
      assert [creator_changeset] = Ecto.Changeset.get_change(changeset, :creator)
      refute Keyword.has_key?(creator_changeset.errors, :role)
    end

    test "round trips through the database, preserving ids of unchanged values" do
      work = work_fixture()

      {:ok, _} =
        work.id
        |> loaded_metadata()
        |> WorkDescriptiveMetadata.changeset(%{
          abstract: ["first", "second"],
          related_url: [%{url: "https://example.org", label: %{id: "RELATED_INFORMATION"}}]
        })
        |> Repo.update()

      reloaded = loaded_metadata(work.id)
      assert WorkDescriptiveMetadata.values(reloaded, :abstract) == ["first", "second"]
      assert [%RelatedURLEntry{url: "https://example.org"}] = reloaded.related_url
      assert WorkDescriptiveMetadata.values(nil, :abstract) == []

      [%MetadataValue{id: first_id}, %MetadataValue{id: second_id}] = reloaded.abstract

      {:ok, _} =
        reloaded
        |> WorkDescriptiveMetadata.changeset(%{abstract: ["first", "third"]})
        |> Repo.update()

      assert [%MetadataValue{id: ^first_id, value: "first"}, %MetadataValue{id: third_id}] =
               loaded_metadata(work.id).abstract

      refute third_id == second_id
    end
  end

  defp loaded_metadata(work_id) do
    WorkDescriptiveMetadata
    |> Repo.get!(work_id)
    |> Repo.preload(WorkDescriptiveMetadata.repeating_fields())
  end

  describe "declaration errors" do
    test "a field declared twice is a compile error" do
      assert_raise ArgumentError, ~r/:title is declared twice/, fn ->
        Code.compile_string("""
        defmodule MetadataSchemaTest.Duplicate do
          use Meadow.Data.Schemas.MetadataSchema, table: "nope", section: "nope"

          metadata do
            string :title
            values :title
          end
        end
        """)
      end
    end

    test "a missing metadata block is a compile error" do
      assert_raise ArgumentError, ~r/no `metadata do ... end` block/, fn ->
        Code.compile_string("""
        defmodule MetadataSchemaTest.Empty do
          use Meadow.Data.Schemas.MetadataSchema, table: "nope", section: "nope"
        end
        """)
      end
    end

    test "kinds" do
      assert MetadataSchema.kinds() == [:string, :coded, :values, :controlled, :entries]
      assert MetadataSchema.column_kinds() ++ MetadataSchema.row_kinds() == MetadataSchema.kinds()
    end
  end
end
