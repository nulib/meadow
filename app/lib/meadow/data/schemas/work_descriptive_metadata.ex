defmodule Meadow.Data.Schemas.WorkDescriptiveMetadata do
  @moduledoc """
  Descriptive metadata embedded in Work records.
  """

  import Ecto.Changeset
  use Ecto.Schema
  alias Meadow.Data.Schemas.{ControlledMetadataEntry, NoteEntry, RelatedURLEntry, ValueEntry}
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

  # Repeating free-text fields carry stable per-item identity via embedded
  # ValueEntry records, so per-item provenance attaches to the item itself rather
  # than being recovered from list order or string comparison. Non-repeating
  # fields stay as plain strings.
  @repeating_string_fields for {f, true} <- @fields, do: f
  @single_string_fields for {f, false} <- @fields, do: f

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

  @timestamps_opts [type: :utc_datetime_usec]
  embedded_schema do
    @repeating_string_fields
    |> Enum.each(fn f ->
      embeds_many f, ValueEntry, on_replace: :delete
    end)

    @single_string_fields
    |> Enum.each(fn f ->
      field f, :string
    end)

    @map_fields
    |> Enum.each(fn f ->
      field f, {:array, :map}, default: []
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

    timestamps()
  end

  def changeset(metadata, params) do
    changeset =
      metadata
      |> cast(normalize_value_entry_params(params), cast_fields())
      |> cast_embed(:notes)
      |> cast_embed(:related_url)

    changeset =
      Enum.reduce(@repeating_string_fields, changeset, fn field, acc ->
        cast_embed(acc, field)
      end)

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

  # Repeating free-text fields are now embeds, so their params must be maps. Accept
  # bare strings (CSV import, AI apply, legacy callers) by normalizing each element
  # to `%{"value" => string}` before `cast_embed`; ids supplied as maps pass through
  # unchanged so identity survives an edit. Handles atom- and string-keyed params.
  defp normalize_value_entry_params(params) when is_map(params) do
    Enum.reduce(@repeating_string_fields, params, fn field, acc ->
      acc
      |> normalize_value_entry_key(field, field)
      |> normalize_value_entry_key(Atom.to_string(field), field)
    end)
  end

  defp normalize_value_entry_params(params), do: params

  defp normalize_value_entry_key(params, key, _field) when not is_map_key(params, key), do: params

  defp normalize_value_entry_key(params, key, _field) do
    case Map.get(params, key) do
      values when is_list(values) -> Map.put(params, key, Enum.map(values, &ValueEntry.normalize/1))
      _ -> params
    end
  end

  # Fields cast directly (non-embed): single-value strings, coded terms, map
  # fields, and EDTF date arrays. Repeating string fields and controlled/note/url
  # embeds are handled via `cast_embed`.
  defp cast_fields, do: @single_string_fields ++ @coded_fields ++ @map_fields ++ @edtf_fields

  def permitted, do: @coded_fields ++ scalar_fields() ++ @map_fields ++ @edtf_fields

  defp scalar_fields, do: @fields |> Enum.map(fn {name, _} -> name end)

  @doc """
  Descriptive field names in their canonical (CSV/column) order. Repeating
  free-text fields are embeds now, so they are no longer in `__schema__(:fields)`;
  this enumerates them in the original declaration order so CSV export columns are
  unchanged.
  """
  def field_names do
    scalar_fields() ++
      @map_fields ++ @coded_fields ++ @controlled_fields ++ @edtf_fields ++ [:notes, :related_url]
  end

  @doc "The repeating free-text fields stored as identified `ValueEntry` embeds."
  def value_entry_fields, do: @repeating_string_fields

  @doc """
  Normalize a descriptive-metadata map for a direct jsonb merge (the planner and
  batch update paths bypass the changeset and write jsonb straight to the column).
  Repeating free-text field values are turned into id-bearing `%{id, value}` maps
  so the stored jsonb is well-formed `ValueEntry` data rather than bare strings.
  Accepts atom or string keys.
  """
  def jsonb_value_entries(descriptive_metadata) when is_map(descriptive_metadata) do
    Map.new(descriptive_metadata, fn {key, value} ->
      if value_entry_field?(key), do: {key, Enum.map(List.wrap(value), &to_value_entry/1)}, else: {key, value}
    end)
  end

  defp value_entry_field?(key) when is_atom(key), do: key in @repeating_string_fields
  defp value_entry_field?(key) when is_binary(key), do: safe_field_atom(key) in @repeating_string_fields

  defp safe_field_atom(key) do
    String.to_existing_atom(key)
  rescue
    ArgumentError -> nil
  end

  defp to_value_entry(%{} = entry) do
    # Idempotent: keep an existing id (atom- or string-keyed) so an id minted at
    # proposal time survives re-normalization at apply time.
    if Map.has_key?(entry, :id) or Map.has_key?(entry, "id"),
      do: entry,
      else: Map.put(entry, :id, Ecto.UUID.generate())
  end

  defp to_value_entry(value) when is_binary(value), do: %{id: Ecto.UUID.generate(), value: value}
end
