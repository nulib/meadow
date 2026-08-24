defmodule Meadow.Data.Schemas.MetadataSchemaTest do
  @moduledoc false
  use Meadow.DataCase

  alias Meadow.Data.Schemas.{
    ControlledMetadataEntry,
    MetadataSchema,
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
               :project_name,
               :project_desc,
               :project_proposer,
               :project_manager,
               :project_task_number,
               :project_cycle,
               :status
             ]

      assert WorkDescriptiveMetadata.__metadata__(:fields) |> Enum.take(4) ==
               [:abstract, :alternate_title, :box_name, :box_number]
    end

    test "section" do
      assert WorkDescriptiveMetadata.__metadata__(:section) == "descriptive"
      assert WorkAdministrativeMetadata.__metadata__(:section) == "administrative"
    end

    test "fields by kind" do
      assert WorkDescriptiveMetadata.__metadata__(:fields, :string) == [:terms_of_use, :title]

      assert WorkDescriptiveMetadata.__metadata__(:fields, :coded) == [
               :license,
               :rights_statement
             ]

      assert :abstract in WorkDescriptiveMetadata.__metadata__(:fields, :values)
      refute :title in WorkDescriptiveMetadata.__metadata__(:fields, :values)

      assert WorkDescriptiveMetadata.__metadata__(:fields, :dates) == [:date_created]
      assert WorkDescriptiveMetadata.__metadata__(:fields, :places) == [:nav_place]

      assert WorkDescriptiveMetadata.__metadata__(:fields, :controlled) ==
               ~w(contributor creator genre language location style_period subject technique)a

      assert WorkDescriptiveMetadata.__metadata__(:fields, :entries) == [:notes, :related_url]

      assert WorkDescriptiveMetadata.__metadata__(:fields, {:entries, NoteEntry}) == [:notes]

      assert WorkAdministrativeMetadata.__metadata__(:fields, :entries) == []
      assert WorkAdministrativeMetadata.__metadata__(:fields, :places) == []

      assert WorkAdministrativeMetadata.__metadata__(:fields, :values) == [
               :project_name,
               :project_desc,
               :project_proposer,
               :project_manager,
               :project_task_number
             ]
    end

    test "kind, options and schema of a field" do
      assert WorkDescriptiveMetadata.__metadata__(:kind, :title) == :string
      assert WorkDescriptiveMetadata.__metadata__(:kind, :license) == :coded
      assert WorkDescriptiveMetadata.__metadata__(:kind, :abstract) == :values
      assert WorkDescriptiveMetadata.__metadata__(:kind, :date_created) == :dates
      assert WorkDescriptiveMetadata.__metadata__(:kind, :nav_place) == :places
      assert WorkDescriptiveMetadata.__metadata__(:kind, :creator) == :controlled
      assert WorkDescriptiveMetadata.__metadata__(:kind, :notes) == :entries
      assert WorkDescriptiveMetadata.__metadata__(:kind, :nope) == nil

      assert WorkDescriptiveMetadata.__metadata__(:options, :contributor) == [role_required: true]
      assert WorkDescriptiveMetadata.__metadata__(:options, :creator) == []
      assert WorkDescriptiveMetadata.__metadata__(:options, :nope) == nil

      # Only the kinds backed by a struct have a schema; plain columns do not
      assert WorkDescriptiveMetadata.__metadata__(:schema, :title) == nil
      assert WorkDescriptiveMetadata.__metadata__(:schema, :abstract) == nil
      assert WorkDescriptiveMetadata.__metadata__(:schema, :date_created) == nil
      assert WorkDescriptiveMetadata.__metadata__(:schema, :creator) == ControlledMetadataEntry
      assert WorkDescriptiveMetadata.__metadata__(:schema, :notes) == NoteEntry
      assert WorkDescriptiveMetadata.__metadata__(:schema, :related_url) == RelatedURLEntry
      assert WorkDescriptiveMetadata.__metadata__(:schema, :nav_place) == NavPlaceEntry
      assert WorkDescriptiveMetadata.__metadata__(:schema, :nope) == nil
    end

    test "permitted, embeds and repeating partition the fields" do
      all = WorkDescriptiveMetadata.__metadata__(:fields)
      permitted = WorkDescriptiveMetadata.permitted()
      embeds = WorkDescriptiveMetadata.__metadata__(:embeds)
      repeating = WorkDescriptiveMetadata.repeating_fields()

      assert permitted == WorkDescriptiveMetadata.__metadata__(:permitted)
      assert repeating == WorkDescriptiveMetadata.__metadata__(:repeating)
      assert embeds == [:nav_place]

      assert repeating == [
               :contributor,
               :creator,
               :genre,
               :language,
               :location,
               :style_period,
               :subject,
               :technique,
               :notes,
               :related_url
             ]

      assert Enum.sort(permitted ++ embeds ++ repeating) == Enum.sort(all)
      assert permitted -- WorkDescriptiveMetadata.__schema__(:fields) == []
      assert embeds -- WorkDescriptiveMetadata.__schema__(:embeds) == []
      assert repeating -- WorkDescriptiveMetadata.__schema__(:associations) == []
    end

    test "a metadata row with no child rows is entirely permitted" do
      assert WorkAdministrativeMetadata.permitted() ==
               WorkAdministrativeMetadata.__metadata__(:fields)

      assert WorkAdministrativeMetadata.repeating_fields() == []
      assert WorkAdministrativeMetadata.__metadata__(:embeds) == []
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

    test "values and dates fields are array columns defaulting to empty" do
      assert WorkDescriptiveMetadata.__schema__(:type, :abstract) == {:array, :string}
      assert WorkAdministrativeMetadata.__schema__(:type, :project_name) == {:array, :string}

      assert WorkDescriptiveMetadata.__schema__(:type, :date_created) ==
               {:array, Meadow.Data.Types.EDTFDate}

      empty = %WorkDescriptiveMetadata{}
      assert empty.abstract == []
      assert empty.date_created == []
    end

    test "places fields are embeds_many, not associations" do
      assert WorkDescriptiveMetadata.__schema__(:embeds) == [:nav_place]
      refute :nav_place in WorkDescriptiveMetadata.__schema__(:associations)

      assert %Ecto.Embedded{
               cardinality: :many,
               related: NavPlaceEntry,
               on_replace: :delete
             } = WorkDescriptiveMetadata.__schema__(:embed, :nav_place)
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
    test "casts columns, values, dates, places and entries fields" do
      changeset =
        WorkDescriptiveMetadata.changeset(%WorkDescriptiveMetadata{}, %{
          title: "Title",
          license: %{id: "http://www.europeana.eu/portal/rights/rr-r.html", scheme: "license"},
          abstract: ["one", "two"],
          date_created: ["1999", %{edtf: "2000"}],
          nav_place: [
            %{"id" => "https://sws.geonames.org/4887398/", "coordinates" => [-87.65, 41.85]}
          ],
          notes: [%{note: "a note", type: %{id: "GENERAL_NOTE", scheme: "note_type"}}]
        })

      assert changeset.valid?, inspect(changeset.errors)
      assert Ecto.Changeset.get_change(changeset, :title) == "Title"
      assert Ecto.Changeset.get_change(changeset, :abstract) == ["one", "two"]

      # A bare string and a `%{edtf: ...}` map are both accepted, and both
      # humanize on the way in
      assert Ecto.Changeset.get_change(changeset, :date_created) == [
               %{edtf: "1999", humanized: "1999"},
               %{edtf: "2000", humanized: "2000"}
             ]

      assert [place] = Ecto.Changeset.get_change(changeset, :nav_place)

      assert place.changes == %{
               place_id: "https://sws.geonames.org/4887398/",
               longitude: -87.65,
               latitude: 41.85
             }

      assert [note] = Ecto.Changeset.get_change(changeset, :notes)
      assert Ecto.Changeset.get_change(note, :note) == "a note"
    end

    test "an invalid date is reported against its position, with the value in the message" do
      changeset =
        WorkDescriptiveMetadata.changeset(%WorkDescriptiveMetadata{}, %{
          date_created: ["1999", "bad_date"]
        })

      refute changeset.valid?

      assert changeset.errors == [
               "date_created#2": {~s'"bad_date" is not a valid EDTF date', []}
             ]
    end

    test "a place needs something to identify it" do
      changeset =
        WorkDescriptiveMetadata.changeset(%WorkDescriptiveMetadata{}, %{
          nav_place: [%{"summary" => "nothing but a summary"}]
        })

      refute changeset.valid?
      assert [place] = Ecto.Changeset.get_change(changeset, :nav_place)
      assert Keyword.has_key?(place.errors, :place_id)
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

    test "columns, arrays and places round trip through the database" do
      work = work_fixture()

      {:ok, _} =
        work.id
        |> loaded_metadata()
        |> WorkDescriptiveMetadata.changeset(%{
          abstract: ["first", "second"],
          date_created: ["1999", "~1968"],
          nav_place: [
            %{"id" => "https://sws.geonames.org/4887398/", "label" => "Chicago"}
          ]
        })
        |> Repo.update()

      reloaded = loaded_metadata(work.id)

      assert reloaded.abstract == ["first", "second"]

      assert reloaded.date_created == [
               %{edtf: "1999", humanized: "1999"},
               %{edtf: "~1968", humanized: "circa 1968"}
             ]

      assert [%NavPlaceEntry{place_id: "https://sws.geonames.org/4887398/", label: "Chicago"}] =
               reloaded.nav_place

      # An array field is replaced wholesale, and emptying it is a real change
      {:ok, _} =
        reloaded
        |> WorkDescriptiveMetadata.changeset(%{abstract: [], nav_place: []})
        |> Repo.update()

      assert loaded_metadata(work.id).abstract == []
      assert loaded_metadata(work.id).nav_place == []
    end

    test "child rows keep their ids when they are re-sent unchanged" do
      work = work_fixture()

      {:ok, _} =
        work.id
        |> loaded_metadata()
        |> WorkDescriptiveMetadata.changeset(%{
          related_url: [
            %{url: "https://example.org/first", label: %{id: "RELATED_INFORMATION"}},
            %{url: "https://example.org/second", label: %{id: "RELATED_INFORMATION"}}
          ]
        })
        |> Repo.update()

      reloaded = loaded_metadata(work.id)

      assert [
               %RelatedURLEntry{id: first_id, url: "https://example.org/first"},
               %RelatedURLEntry{id: second_id, url: "https://example.org/second"}
             ] = reloaded.related_url

      {:ok, _} =
        reloaded
        |> WorkDescriptiveMetadata.changeset(%{
          related_url: [
            %{url: "https://example.org/first", label: %{id: "RELATED_INFORMATION"}},
            %{url: "https://example.org/third", label: %{id: "RELATED_INFORMATION"}}
          ]
        })
        |> Repo.update()

      assert [
               %RelatedURLEntry{id: ^first_id, url: "https://example.org/first"},
               %RelatedURLEntry{id: third_id, url: "https://example.org/third"}
             ] = loaded_metadata(work.id).related_url

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
      assert MetadataSchema.kinds() == [
               :string,
               :coded,
               :values,
               :dates,
               :places,
               :controlled,
               :entries
             ]

      assert MetadataSchema.column_kinds() ++
               MetadataSchema.embed_kinds() ++
               MetadataSchema.row_kinds() == MetadataSchema.kinds()
    end
  end
end
