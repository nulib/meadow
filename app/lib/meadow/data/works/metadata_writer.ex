defmodule Meadow.Data.Works.MetadataWriter do
  @moduledoc """
  Set-based metadata updates across many works at once (batch updates, plan
  changes). Replaces the old `replace_controlled_value`/`merge_jsonb_values`
  plpgsql functions with `insert_all`/`delete_all`/`update_all` on the
  relational metadata tables.

  Values are validated through the same entry changesets the work form uses,
  so an invalid coded term, controlled term or EDTF date raises before any
  row is written. Every call bumps `works.updated_at` so the search index
  (and the ARK/WAL listeners) pick the change up.
  """

  import Ecto.Query, warn: false

  alias Meadow.Data.Schemas.{
    ControlledMetadataEntry,
    DateCreatedEntry,
    MetadataValue,
    NoteEntry,
    RelatedURLEntry,
    Work,
    WorkAdministrativeMetadata,
    WorkDescriptiveMetadata
  }

  alias Meadow.Repo

  @descriptive_multi WorkDescriptiveMetadata.__metadata__(:fields, :values)
  @administrative_multi WorkAdministrativeMetadata.__metadata__(:fields, :values)
  @controlled_fields WorkDescriptiveMetadata.__metadata__(:fields, :controlled)
  @entry_fields WorkDescriptiveMetadata.__metadata__(:fields, :entries) -- [:nav_place]

  @doc """
  Merge `%{descriptive_metadata: %{...}, administrative_metadata: %{...}}` into
  every work in `work_ids`. `mode` is `:append` (add to repeating fields) or
  `:replace` (replace repeating fields). Scalar and coded fields are always set
  (replaced) regardless of mode. Controlled fields are not handled here; see
  `replace_controlled_values/4`.
  """
  def merge(work_ids, values, mode) when mode in [:append, :replace] do
    values = atomize(values)

    merge_section(work_ids, :descriptive, Map.get(values, :descriptive_metadata) || %{}, mode)

    merge_section(
      work_ids,
      :administrative,
      Map.get(values, :administrative_metadata) || %{},
      mode
    )

    touch(work_ids)
    work_ids
  end

  defp merge_section(_work_ids, _section, values, _mode) when map_size(values) == 0, do: :ok

  defp merge_section(work_ids, :descriptive, values, mode) do
    Enum.each(values, fn
      {field, value} when field in @descriptive_multi ->
        write_values(work_ids, "descriptive", field, List.wrap(value), mode)

      {field, value} when field in @controlled_fields ->
        raise ArgumentError,
              "controlled field #{field} must be updated with replace_controlled_values/4, got #{inspect(value)}"

      {field, value} when field in @entry_fields ->
        write_entries(work_ids, field, List.wrap(value), mode)

      {:nav_place, _value} ->
        raise ArgumentError, "nav_place cannot be batch updated"

      {field, value} ->
        set_scalar(work_ids, WorkDescriptiveMetadata, field, value)
    end)
  end

  defp merge_section(work_ids, :administrative, values, mode) do
    Enum.each(values, fn
      {field, value} when field in @administrative_multi ->
        write_values(work_ids, "administrative", field, List.wrap(value), mode)

      {field, value} ->
        set_scalar(work_ids, WorkAdministrativeMetadata, field, value)
    end)
  end

  @doc """
  Remove `remove` entries from and add `add` entries to a controlled field on
  every work in `work_ids`. Entries are `%{term: uri | %{id: uri}, role: %{id, scheme} | nil}`.
  Entries already present on a work (same term and role) are not added twice.
  """
  def replace_controlled_values(work_ids, field, remove, add) do
    field = to_string(field)
    remove = remove |> List.wrap() |> Enum.map(&normalize_controlled/1)
    add = add |> List.wrap() |> Enum.map(&normalize_controlled/1)

    delete_controlled(work_ids, field, remove)
    add_controlled(work_ids, field, add)
    touch(work_ids)
    work_ids
  end

  @doc "Bump `updated_at` on the given works"
  def touch([]), do: :ok

  def touch(work_ids) do
    from(w in Work, where: w.id in ^work_ids)
    |> Repo.update_all(set: [updated_at: DateTime.utc_now()])
  end

  # -- free text values ---------------------------------------------------

  defp write_values(work_ids, section, field, values, mode) do
    field = to_string(field)
    values = values |> Enum.map(&MetadataValue.value/1) |> Enum.reject(&is_nil/1)

    if mode == :replace do
      from(v in MetadataValue,
        where: v.work_id in ^work_ids and v.section == ^section and v.field == ^field
      )
      |> Repo.delete_all()
    end

    insert_rows(
      MetadataValue,
      work_ids,
      starting_positions(MetadataValue, work_ids, section: section, field: field),
      fn work_id, value, position ->
        %{
          id: Ecto.UUID.generate(),
          work_id: work_id,
          section: section,
          field: field,
          position: position,
          value: value
        }
      end,
      values
    )
  end

  # -- notes / related urls / dates -----------------------------------------

  defp write_entries(work_ids, field, entries, mode) do
    schema = WorkDescriptiveMetadata.__metadata__(:schema, field)

    attrs =
      Enum.map(entries, fn entry ->
        schema.__struct__()
        |> schema.changeset(schema.to_params(entry), 0)
        |> apply_changes!(field)
        |> Map.from_struct()
        |> Map.take(entry_columns(schema))
      end)

    if mode == :replace do
      from(e in schema, where: e.work_id in ^work_ids) |> Repo.delete_all()
    end

    insert_rows(
      schema,
      work_ids,
      starting_positions(schema, work_ids, []),
      fn work_id, attr, position ->
        Map.merge(attr, %{id: Ecto.UUID.generate(), work_id: work_id, position: position})
      end,
      attrs
    )
  end

  defp entry_columns(NoteEntry), do: [:note, :type]
  defp entry_columns(RelatedURLEntry), do: [:url, :label]
  defp entry_columns(DateCreatedEntry), do: [:edtf, :humanized]

  # -- controlled terms -------------------------------------------------------

  defp delete_controlled(_work_ids, _field, []), do: :ok

  defp delete_controlled(work_ids, field, remove) do
    condition =
      Enum.reduce(remove, false, fn %{term: term, role: role}, acc ->
        clause =
          case role do
            nil ->
              dynamic([e], type(e.term, :string) == ^term and is_nil(e.role))

            role_id ->
              dynamic([e], type(e.term, :string) == ^term and type(e.role, :string) == ^role_id)
          end

        dynamic([e], ^acc or ^clause)
      end)

    from(e in ControlledMetadataEntry,
      where: e.work_id in ^work_ids and e.field == ^field,
      where: ^condition
    )
    |> Repo.delete_all()
  end

  defp add_controlled(_work_ids, _field, []), do: :ok

  defp add_controlled(work_ids, field, add) do
    # validate (and resolve the role scheme) through the entry changeset once per distinct entry
    validated =
      Enum.map(add, fn %{term: term, role: role_id} = entry ->
        params = %{term: term, role: role_id && %{id: role_id}}

        changeset =
          %ControlledMetadataEntry{field: field}
          |> ControlledMetadataEntry.changeset(params, 0)

        struct = apply_changes!(changeset, field)
        Map.put(entry, :role_scheme, struct.role_scheme)
      end)

    existing =
      from(e in ControlledMetadataEntry,
        where: e.work_id in ^work_ids and e.field == ^field,
        select: {e.work_id, type(e.term, :string), type(e.role, :string)}
      )
      |> Repo.all()
      |> MapSet.new()

    positions = starting_positions(ControlledMetadataEntry, work_ids, field: field)

    rows =
      work_ids
      |> Enum.flat_map(fn work_id ->
        validated
        |> Enum.reject(&MapSet.member?(existing, {work_id, &1.term, &1.role}))
        |> Enum.with_index(Map.get(positions, work_id, 0))
        |> Enum.map(fn {%{term: term, role: role_id, role_scheme: role_scheme}, position} ->
          %{
            id: Ecto.UUID.generate(),
            work_id: work_id,
            field: field,
            position: position,
            term: term,
            role: role_id,
            role_scheme: role_scheme
          }
        end)
      end)

    rows |> Enum.chunk_every(1000) |> Enum.each(&Repo.insert_all(ControlledMetadataEntry, &1))
  end

  defp normalize_controlled(entry) do
    entry = atomize(entry)

    %{
      term: ControlledMetadataEntry.term_id(Map.get(entry, :term)),
      role: ControlledMetadataEntry.role_id(Map.get(entry, :role))
    }
  end

  # -- scalar / coded columns -------------------------------------------------

  defp set_scalar(work_ids, schema, field, value) do
    unless field in schema.permitted() do
      raise ArgumentError, "#{inspect(schema)} has no batch-updatable field #{field}"
    end

    struct = schema.__struct__() |> schema.changeset(%{field => value}) |> apply_changes!(field)

    from(m in schema, where: m.work_id in ^work_ids)
    |> Repo.update_all(set: [{field, Map.get(struct, field)}, {:updated_at, DateTime.utc_now()}])
  end

  # -- helpers ----------------------------------------------------------------

  # next free position per work, for appends
  defp starting_positions(schema, work_ids, filters) do
    query =
      from(e in schema,
        where: e.work_id in ^work_ids,
        group_by: e.work_id,
        select: {e.work_id, max(e.position)}
      )

    query =
      Enum.reduce(filters, query, fn {column, value}, q ->
        from(e in q, where: field(e, ^column) == ^value)
      end)

    query
    |> Repo.all()
    |> Map.new(fn {work_id, max} -> {work_id, (max || -1) + 1} end)
  end

  defp insert_rows(_schema, _work_ids, _positions, _row_fun, []), do: :ok

  defp insert_rows(schema, work_ids, positions, row_fun, items) do
    work_ids
    |> Enum.flat_map(fn work_id ->
      items
      |> Enum.with_index(Map.get(positions, work_id, 0))
      |> Enum.map(fn {item, position} -> row_fun.(work_id, item, position) end)
    end)
    |> Enum.chunk_every(1000)
    |> Enum.each(&Repo.insert_all(schema, &1))
  end

  defp apply_changes!(%Ecto.Changeset{valid?: true} = changeset, _field),
    do: Ecto.Changeset.apply_changes(changeset)

  defp apply_changes!(%Ecto.Changeset{} = changeset, field) do
    errors = Ecto.Changeset.traverse_errors(changeset, fn {msg, _opts} -> msg end)
    raise ArgumentError, "invalid value for #{field}: #{inspect(errors)}"
  end

  defp atomize(%{__struct__: _} = struct), do: struct |> Map.from_struct() |> atomize()

  defp atomize(%{} = map) do
    Map.new(map, fn
      {key, value} when is_binary(key) -> {String.to_existing_atom(key), value}
      {key, value} -> {key, value}
    end)
  end

  defp atomize(other), do: other
end
