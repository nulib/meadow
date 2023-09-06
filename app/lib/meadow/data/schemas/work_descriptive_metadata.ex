defmodule Meadow.Data.Schemas.WorkDescriptiveMetadata do
  @moduledoc """
  Descriptive metadata embedded in Work records.
  """

  import Ecto.Changeset
  use Ecto.Schema
  alias Meadow.Data.Schemas.{ArkCache, ControlledMetadataEntry, NoteEntry, RelatedURLEntry}
  alias Meadow.Data.Types

  # {field_name, repeating}
  @fields [
    {:abstract, true},
    {:alternate_title, true},
    {:ark, false},
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

  @timestamps_opts [type: :utc_datetime_usec]
  embedded_schema do
    @fields
    |> Enum.each(fn
      {f, true} -> field f, {:array, :string}, default: []
      {f, false} -> field f, :string
    end)

    @coded_fields
    |> Enum.each(fn f ->
      field f, Types.CodedTerm
    end)

    @controlled_fields
    |> Enum.each(fn f ->
      embeds_many(f, ControlledMetadataEntry, on_replace: :delete)
    end)

    @edtf_fields
    |> Enum.each(fn f ->
      field f, {:array, Types.EDTFDate}, default: []
    end)

    embeds_many(:notes, NoteEntry, on_replace: :delete)
    embeds_many(:related_url, RelatedURLEntry, on_replace: :delete)

    belongs_to(:cached_ark, ArkCache, foreign_key: :ark, references: :ark, define_field: false)

    timestamps()
  end

  def changeset(metadata, params) do
    changeset =
      metadata
      |> cast(params, permitted())
      |> cast_embed(:notes)
      |> cast_embed(:related_url)

    @controlled_fields
    |> Enum.reduce(changeset, fn
      :subject, acc ->
        cast_embed(acc, :subject, with: &ControlledMetadataEntry.changeset_with_role/2)

      :contributor, acc ->
        cast_embed(acc, :contributor, with: &ControlledMetadataEntry.changeset_with_role/2)

      field, acc ->
        cast_embed(acc, field)
    end)
  end

  def permitted, do: @coded_fields ++ scalar_fields() ++ @edtf_fields

  defp scalar_fields, do: @fields |> Enum.map(fn {name, _} -> name end)
  def field_names, do: __schema__(:fields) -- [:id, :inserted_at, :updated_at]
end
