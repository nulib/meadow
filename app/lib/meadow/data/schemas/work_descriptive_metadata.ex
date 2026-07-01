defmodule Meadow.Data.Schemas.WorkDescriptiveMetadata do
  @moduledoc """
  Descriptive metadata embedded in Work records.
  """

  import Ecto.Changeset
  use Ecto.Schema
  alias Meadow.Data.ItemIdentity
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
      |> cast(normalize_item_params(metadata, params), cast_fields())
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

  # Identified embedded items: the normalizer applied to each incoming element
  # (repeating free-text fields accept bare strings; notes/related URLs are
  # already maps) and the natural key that preserves an id-less item's identity
  # through `ItemIdentity.rehydrate/3`.
  @item_identity_fields Map.new(@repeating_string_fields, fn field ->
                          {field, {&ValueEntry.normalize/1, &ItemIdentity.value_key/1}}
                        end)
                        |> Map.merge(%{
                          notes: {&Function.identity/1, &ItemIdentity.note_key/1},
                          related_url: {&Function.identity/1, &ItemIdentity.related_url_key/1}
                        })

  # Repeating free-text fields are embeds, so their params must be maps: accept
  # bare strings (CSV import, AI apply, legacy callers) by normalizing each
  # element to `%{"value" => string}` before `cast_embed`. Then rehydrate ids for
  # every identified embed (free-text values, notes, related URLs): params that
  # echo an id keep it — the Ecto contract — and id-less params keep their
  # identity when their content is unchanged (`ItemIdentity.rehydrate/3`).
  # Without that, `on_replace: :delete` discards every id-less entry and
  # autogenerate remints, silently severing per-item provenance on a save that
  # changed nothing. Handles atom- and string-keyed params.
  defp normalize_item_params(metadata, params) when is_map(params) do
    Enum.reduce(@item_identity_fields, params, fn {field, funs}, acc ->
      existing = existing_entries(metadata, field)

      acc
      |> normalize_item_key(field, existing, funs)
      |> normalize_item_key(Atom.to_string(field), existing, funs)
    end)
  end

  defp normalize_item_params(_metadata, params), do: params

  defp existing_entries(%__MODULE__{} = metadata, field), do: Map.get(metadata, field) || []
  defp existing_entries(_metadata, _field), do: []

  defp normalize_item_key(params, key, _existing, _funs) when not is_map_key(params, key),
    do: params

  defp normalize_item_key(params, key, existing, {normalize_fun, key_fun}) do
    case Map.get(params, key) do
      values when is_list(values) ->
        normalized =
          values
          |> Enum.map(normalize_fun)
          |> ItemIdentity.rehydrate(existing, key_fun)

        Map.put(params, key, normalized)

      _ ->
        params
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
  Return the descriptive metadata with the repeating free-text fields flattened to
  bare strings — the boundary view for external consumers (notably the AI agent)
  that should neither see nor echo back the internal per-item `ValueEntry` ids. An
  array of `%{id, value}` objects reads like a controlled-term field, so exposing
  it leads an agent to propose controlled-style `{term: {id}}` add/delete
  operations instead of a plain free-text replace. The ids are minted server-side
  at the plan-change boundary (`Planner.normalize_value_entry_operations/1`), so an
  agent only ever needs the strings. Mirrors the search-index / CSV boundaries,
  which already flatten via `ValueEntry.values/1`.
  """
  def flatten_value_entries(%__MODULE__{} = metadata) do
    Enum.reduce(@repeating_string_fields, metadata, fn field, acc ->
      Map.update!(acc, field, &ValueEntry.values/1)
    end)
  end

  def flatten_value_entries(metadata), do: metadata

  @doc """
  Flatten the repeating free-text fields of a raw descriptive-metadata *map* (as
  stored in plan-change `add`/`delete`/`replace` operations) to bare strings — the
  map-based counterpart of `flatten_value_entries/1`, for echoing plan operations
  back to the agent without the internal `ValueEntry` ids. Accepts atom or string
  keys; non-value-entry fields (controlled terms, notes, …) pass through untouched.
  """
  def flatten_value_entries_map(metadata) when is_map(metadata) do
    Map.new(metadata, fn {key, value} ->
      if value_entry_field?(key), do: {key, ValueEntry.values(value)}, else: {key, value}
    end)
  end

  def flatten_value_entries_map(metadata), do: metadata

  # Notes and related URLs are embeds with an autogenerated primary key. Written
  # through the changeset they get an id for free, but the direct-jsonb merge below
  # bypasses that — so, like ValueEntry fields, they must be stamped with an id
  # here, or the stored embed has a nil primary key and the next changeset edit of
  # the work fails with "missing primary key value".
  @id_bearing_object_fields [:notes, :related_url]

  @doc """
  Normalize a descriptive-metadata map for a direct jsonb merge (the planner and
  batch update paths bypass the changeset and write jsonb straight to the column).
  Repeating free-text field values are turned into id-bearing `%{id, value}` maps
  so the stored jsonb is well-formed `ValueEntry` data rather than bare strings, and
  notes/related URLs are stamped with an id so their embeds carry a primary key.
  Accepts atom or string keys.
  """
  def jsonb_value_entries(descriptive_metadata) when is_map(descriptive_metadata) do
    Map.new(descriptive_metadata, fn {key, value} ->
      cond do
        value_entry_field?(key) -> {key, Enum.map(List.wrap(value), &to_value_entry/1)}
        id_bearing_object_field?(key) -> {key, Enum.map(List.wrap(value), &ensure_id/1)}
        true -> {key, value}
      end
    end)
  end

  defp value_entry_field?(key) when is_atom(key), do: key in @repeating_string_fields

  defp value_entry_field?(key) when is_binary(key),
    do: safe_field_atom(key) in @repeating_string_fields

  defp id_bearing_object_field?(key) when is_atom(key), do: key in @id_bearing_object_fields

  defp id_bearing_object_field?(key) when is_binary(key),
    do: safe_field_atom(key) in @id_bearing_object_fields

  defp safe_field_atom(key) do
    String.to_existing_atom(key)
  rescue
    ArgumentError -> nil
  end

  defp to_value_entry(%{} = entry), do: ensure_id(entry)

  defp to_value_entry(value) when is_binary(value),
    do: %{"id" => Ecto.UUID.generate(), "value" => value}

  # Idempotent: keep an existing id (atom- or string-keyed) so an id minted at
  # proposal time survives re-normalization at apply time; otherwise mint one,
  # stamped in the entry's own key style — Ecto and clarity both frown on
  # mixed-key maps, and this data may be re-cast later.
  defp ensure_id(%{} = entry) do
    cond do
      Map.has_key?(entry, :id) or Map.has_key?(entry, "id") ->
        entry

      Enum.any?(Map.keys(entry), &is_binary/1) ->
        Map.put(entry, "id", Ecto.UUID.generate())

      true ->
        Map.put(entry, :id, Ecto.UUID.generate())
    end
  end

  defp ensure_id(entry), do: entry
end
