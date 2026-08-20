defmodule Meadow.Data.Schemas.WorkDescriptiveMetadata do
  @moduledoc """
  Descriptive metadata for a Work.

  Scalar and coded fields live on the `work_descriptive_metadata` row (one per
  work, keyed by `work_id`). Repeating fields are child rows: free text in
  `work_metadata_values`, controlled terms in `work_controlled_entries`, and
  notes, related URLs, dates and places in their own tables. Every repeating
  association is declared with `where:` (so reads are filtered to the field)
  and `defaults:` (so rows built through `cast_assoc` are stamped with the
  field), ordered by `position`.
  """

  import Ecto.Changeset
  use Ecto.Schema

  alias Meadow.Data.Schemas.{
    ControlledMetadataEntry,
    DateCreatedEntry,
    MetadataValue,
    MultiValued,
    NavPlaceEntry,
    NoteEntry,
    RelatedURLEntry,
    Work
  }

  alias Meadow.Data.Types

  # {field_name, repeating}
  @fields [
    {:abstract, true},
    {:alternate_title, true},
    {:box_name, true},
    {:box_number, true},
    {:caption, true},
    {:catalog_key, true},
    {:citation, true},
    {:cultural_context, true},
    {:description, true},
    {:folder_name, true},
    {:folder_number, true},
    {:identifier, true},
    {:keywords, true},
    {:legacy_identifier, true},
    {:terms_of_use, false},
    {:physical_description_material, true},
    {:physical_description_size, true},
    {:provenance, true},
    {:publisher, true},
    {:related_material, true},
    {:rights_holder, true},
    {:scope_and_contents, true},
    {:series, true},
    {:source, true},
    {:table_of_contents, true},
    {:title, false}
  ]

  @map_fields [
    :nav_place
  ]

  @coded_fields [
    :license,
    :rights_statement
  ]

  @controlled_fields [
    :contributor,
    :creator,
    :genre,
    :language,
    :location,
    :style_period,
    :subject,
    :technique
  ]

  @edtf_fields [
    :date_created
  ]

  @role_required_fields [:subject, :contributor]

  @multi_valued_fields @fields |> Enum.filter(&elem(&1, 1)) |> Enum.map(&elem(&1, 0))
  @scalar_fields @fields |> Enum.reject(&elem(&1, 1)) |> Enum.map(&elem(&1, 0))
  @entry_fields [:notes, :related_url] ++ @edtf_fields ++ @map_fields

  @primary_key false
  @foreign_key_type Ecto.UUID
  @timestamps_opts [type: :utc_datetime_usec]
  schema "work_descriptive_metadata" do
    belongs_to(:work, Work, primary_key: true)

    field :title, :string
    field :terms_of_use, :string

    @coded_fields
    |> Enum.each(fn f ->
      field f, Types.CodedTerm, scheme: to_string(f), source: :"#{f}_id"
    end)

    @multi_valued_fields
    |> Enum.each(fn f ->
      has_many f, MetadataValue,
        foreign_key: :work_id,
        references: :work_id,
        where: [section: "descriptive", field: to_string(f)],
        defaults: [section: "descriptive", field: to_string(f)],
        preload_order: [asc: :position],
        on_replace: :delete
    end)

    @controlled_fields
    |> Enum.each(fn f ->
      has_many f, ControlledMetadataEntry,
        foreign_key: :work_id,
        references: :work_id,
        where: [field: to_string(f)],
        defaults: [field: to_string(f)],
        preload_order: [asc: :position],
        on_replace: :delete
    end)

    has_many :notes, NoteEntry,
      foreign_key: :work_id,
      references: :work_id,
      preload_order: [asc: :position],
      on_replace: :delete

    has_many :related_url, RelatedURLEntry,
      foreign_key: :work_id,
      references: :work_id,
      preload_order: [asc: :position],
      on_replace: :delete

    has_many :date_created, DateCreatedEntry,
      foreign_key: :work_id,
      references: :work_id,
      preload_order: [asc: :position],
      on_replace: :delete

    has_many :nav_place, NavPlaceEntry,
      foreign_key: :work_id,
      references: :work_id,
      preload_order: [asc: :position],
      on_replace: :delete

    timestamps()
  end

  def changeset(metadata, params) do
    changeset = cast(metadata, params, permitted())

    changeset =
      Enum.reduce(@multi_valued_fields, changeset, fn field, acc ->
        MultiValued.cast_entries(acc, field,
          with: &MetadataValue.changeset/3,
          key: &MetadataValue.value/1,
          normalize: &MetadataValue.to_params/1
        )
      end)

    changeset =
      Enum.reduce(@controlled_fields, changeset, fn field, acc ->
        MultiValued.cast_entries(acc, field,
          with: controlled_changeset_fun(field),
          key: &ControlledMetadataEntry.natural_key/1,
          normalize: &ControlledMetadataEntry.to_params/1
        )
      end)

    changeset
    |> MultiValued.cast_entries(:notes,
      with: &NoteEntry.changeset/3,
      key: &NoteEntry.natural_key/1,
      normalize: &NoteEntry.to_params/1
    )
    |> MultiValued.cast_entries(:related_url,
      with: &RelatedURLEntry.changeset/3,
      key: &RelatedURLEntry.natural_key/1,
      normalize: &RelatedURLEntry.to_params/1
    )
    |> MultiValued.cast_entries(:date_created,
      with: &DateCreatedEntry.changeset/3,
      key: &DateCreatedEntry.natural_key/1,
      normalize: &DateCreatedEntry.to_params/1
    )
    |> MultiValued.cast_entries(:nav_place,
      with: &NavPlaceEntry.changeset/3,
      key: &NavPlaceEntry.natural_key/1,
      normalize: &NavPlaceEntry.to_params/1
    )
  end

  defp controlled_changeset_fun(field) when field in @role_required_fields,
    do: &ControlledMetadataEntry.changeset_with_role/3

  defp controlled_changeset_fun(_field), do: &ControlledMetadataEntry.changeset/3

  @doc "Columns cast directly on the metadata row"
  def permitted, do: @coded_fields ++ @scalar_fields

  @doc """
  All metadata field names, in the order the jsonb embed declared them (CSV
  export headers depend on this order)
  """
  def field_names,
    do:
      Enum.map(@fields, &elem(&1, 0)) ++
        @map_fields ++
        @coded_fields ++ @controlled_fields ++ @edtf_fields ++ [:notes, :related_url]

  def scalar_fields, do: @scalar_fields
  def multi_valued_fields, do: @multi_valued_fields
  def controlled_fields, do: @controlled_fields
  def coded_fields, do: @coded_fields
  def edtf_fields, do: @edtf_fields
  def map_fields, do: @map_fields
  def entry_fields, do: @entry_fields
  def role_required_fields, do: @role_required_fields

  @doc "Every repeating (child-row) field"
  def repeating_fields, do: @multi_valued_fields ++ @controlled_fields ++ @entry_fields

  @doc "Preloads for every repeating field"
  def preloads, do: repeating_fields()

  @doc "Plain string values of a repeating free-text field"
  def values(%__MODULE__{} = metadata, field) when field in @multi_valued_fields,
    do: metadata |> Map.get(field) |> MetadataValue.values()

  def values(nil, _field), do: []
end
