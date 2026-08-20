defmodule Meadow.Data.Planner.Operations do
  @moduledoc """
  Convert plan change operation maps
  (`%{add: %{descriptive_metadata: %{subject: [...]}, visibility: %{...}}, delete: ..., replace: ...}`)
  to `plan_change_operations` rows and back. Each proposed item becomes one
  row with the value in typed columns; repeating fields keep their order in
  `position`. Rebuilt maps are atom-keyed.
  """

  alias Meadow.Data.Schemas.{
    MetadataValue,
    WorkAdministrativeMetadata,
    WorkDescriptiveMetadata
  }

  @operations [:add, :delete, :replace]
  @sections ~w(descriptive_metadata administrative_metadata)
  @top_level_coded ~w(visibility work_type behavior)
  @top_level_boolean ~w(published)

  @doc """
  Flatten an operations map into row attribute maps. Returns
  `{:error, message}` for a value that cannot be represented.
  """
  def to_rows(operations) when is_map(operations) do
    rows =
      Enum.flat_map(@operations, fn operation ->
        case map_value(operations, operation) do
          %{} = values -> Enum.flat_map(values, &flatten_top_level(operation, &1))
          _ -> []
        end
      end)

    case Enum.find(rows, &match?({:error, _}, &1)) do
      nil -> {:ok, rows}
      {:error, message} -> {:error, message}
    end
  end

  def to_rows(_), do: {:ok, []}

  defp flatten_top_level(operation, {key, value}) do
    name = to_string(key)

    if name in @sections and is_map(value) do
      Enum.flat_map(value, fn {field, item} ->
        flatten_field(operation, name, to_string(field), item)
      end)
    else
      flatten_field(operation, nil, name, value)
    end
  end

  defp flatten_field(operation, section, field, value) do
    base = %{operation: to_string(operation), section: section, field: field}

    case {field_kind(section, field), value} do
      {{:list, kind}, values} ->
        values
        |> List.wrap()
        |> Enum.with_index()
        |> Enum.map(fn {item, position} ->
          encode(kind, item, Map.put(base, :position, position))
        end)

      # a single-valued field wrapped in a one-element list is accepted
      {{:scalar, kind}, [item]} ->
        [encode(kind, item, Map.put(base, :position, nil))]

      {{:scalar, _kind}, items} when is_list(items) ->
        [{:error, "#{field} holds a single value, got #{length(items)}"}]

      {{:scalar, kind}, item} ->
        [encode(kind, item, Map.put(base, :position, nil))]

      {:unsupported, _} ->
        [{:error, "#{field} cannot be proposed in a plan change"}]
    end
  end

  # What shape a field holds: a list or scalar of a value kind
  @descriptive_kinds Map.new(
                       Enum.map(
                         WorkDescriptiveMetadata.multi_valued_fields(),
                         &{&1, {:list, :string}}
                       ) ++
                         Enum.map(
                           WorkDescriptiveMetadata.scalar_fields(),
                           &{&1, {:scalar, :string}}
                         ) ++
                         Enum.map(
                           WorkDescriptiveMetadata.coded_fields(),
                           &{&1, {:scalar, :coded}}
                         ) ++
                         Enum.map(
                           WorkDescriptiveMetadata.controlled_fields(),
                           &{&1, {:list, :controlled}}
                         ) ++
                         [
                           date_created: {:list, :edtf},
                           notes: {:list, :note},
                           related_url: {:list, :related_url}
                         ]
                     )
  @administrative_kinds Map.new(
                          Enum.map(
                            WorkAdministrativeMetadata.multi_valued_fields(),
                            &{&1, {:list, :string}}
                          ) ++
                            Enum.map(
                              WorkAdministrativeMetadata.scalar_fields(),
                              &{&1, {:scalar, :string}}
                            ) ++
                            Enum.map(
                              WorkAdministrativeMetadata.coded_fields(),
                              &{&1, {:scalar, :coded}}
                            )
                        )
  @section_kinds %{
    "descriptive_metadata" => @descriptive_kinds,
    "administrative_metadata" => @administrative_kinds
  }

  defp field_kind(nil, field) when field in @top_level_coded, do: {:scalar, :coded}
  defp field_kind(nil, field) when field in @top_level_boolean, do: {:scalar, :boolean}
  defp field_kind(nil, _field), do: {:scalar, :string}

  defp field_kind(section, field) do
    kinds = Map.fetch!(@section_kinds, section)
    Map.get(kinds, String.to_existing_atom(field), :unsupported)
  rescue
    ArgumentError -> :unsupported
  end

  # -- encoding one item ----------------------------------------------------

  defp encode(_kind, nil, base), do: Map.put(base, :value_kind, "null")

  defp encode(:string, value, base),
    do:
      Map.merge(base, %{
        value_kind: "string",
        value_text: to_string(MetadataValue.value(value) || value)
      })

  defp encode(:boolean, value, base),
    do: Map.merge(base, %{value_kind: "boolean", value_text: to_string(value)})

  defp encode(:coded, value, base),
    do: base |> Map.put(:value_kind, "coded") |> Map.merge(coded(value))

  defp encode(:edtf, value, base) when is_binary(value),
    do: Map.merge(base, %{value_kind: "edtf", edtf: value})

  defp encode(:edtf, %{} = value, base),
    do:
      Map.merge(base, %{
        value_kind: "edtf",
        edtf: map_value(value, :edtf),
        humanized: map_value(value, :humanized)
      })

  defp encode(:controlled, %{} = value, base) do
    base
    |> Map.put(:value_kind, "controlled")
    |> Map.merge(term_columns(map_value(value, :term)))
    |> Map.merge(role_columns(map_value(value, :role)))
  end

  defp encode(:controlled, value, base) when is_binary(value),
    do: encode(:controlled, %{term: value}, base)

  defp encode(:note, %{} = value, base) do
    base
    |> Map.merge(%{value_kind: "note", value_text: map_value(value, :note)})
    |> Map.merge(coded(map_value(value, :type)))
  end

  defp encode(:related_url, %{} = value, base) do
    base
    |> Map.merge(%{value_kind: "related_url", value_text: map_value(value, :url)})
    |> Map.merge(coded(map_value(value, :label)))
  end

  defp encode(_kind, value, base),
    do: Map.merge(base, %{value_kind: "string", value_text: to_string(value)})

  defp coded(nil), do: %{}
  defp coded(id) when is_binary(id), do: %{coded_id: id}

  defp coded(%{} = map),
    do: %{
      coded_id: map_value(map, :id),
      coded_scheme: map_value(map, :scheme),
      coded_label: map_value(map, :label)
    }

  # A bare term string is a URI (id) when it parses as one, otherwise a label
  defp term_columns(%{} = term),
    do: %{term_id: map_value(term, :id), term_label: map_value(term, :label)}

  defp term_columns(term) when is_binary(term) do
    case URI.parse(term) do
      %URI{scheme: scheme} when is_binary(scheme) -> %{term_id: term}
      _ -> %{term_label: term}
    end
  end

  defp term_columns(_), do: %{}

  defp role_columns(nil), do: %{}
  defp role_columns(id) when is_binary(id), do: %{role_id: id}

  defp role_columns(%{} = role),
    do: %{
      role_id: map_value(role, :id),
      role_scheme: map_value(role, :scheme),
      role_label: map_value(role, :label)
    }

  # -- decoding rows ----------------------------------------------------------

  @doc """
  Rebuild the `%{add:, delete:, replace:}` maps from rows. Operations with no
  rows are `%{}`.
  """
  def to_maps(rows) do
    by_operation = Enum.group_by(rows, & &1.operation)

    Map.new(@operations, fn operation ->
      {operation, by_operation |> Map.get(to_string(operation), []) |> build_operation()}
    end)
  end

  defp build_operation(rows) do
    rows
    |> Enum.group_by(& &1.section)
    |> Enum.reduce(%{}, fn
      {nil, top_level}, acc ->
        Map.merge(acc, build_fields(nil, top_level))

      {section, section_rows}, acc ->
        Map.put(acc, String.to_existing_atom(section), build_fields(section, section_rows))
    end)
  end

  defp build_fields(section, rows) do
    rows
    |> Enum.group_by(& &1.field)
    |> Map.new(fn {field, field_rows} ->
      value =
        case field_kind(section, field) do
          {:list, _} -> field_rows |> Enum.sort_by(& &1.position) |> Enum.map(&decode/1)
          _ -> field_rows |> List.first() |> decode()
        end

      {String.to_existing_atom(field), value}
    end)
  end

  defp decode(%{value_kind: "null"}), do: nil
  defp decode(%{value_kind: "string", value_text: text}), do: text
  defp decode(%{value_kind: "boolean", value_text: text}), do: text == "true"
  defp decode(%{value_kind: "coded"} = row), do: coded_map(row)
  defp decode(%{value_kind: "edtf", edtf: edtf, humanized: nil}), do: %{edtf: edtf}

  defp decode(%{value_kind: "edtf", edtf: edtf, humanized: humanized}),
    do: %{edtf: edtf, humanized: humanized}

  defp decode(%{value_kind: "controlled"} = row),
    do: %{term: term_value(row)} |> maybe_put(:role, role_map(row))

  defp decode(%{value_kind: "note"} = row), do: %{note: row.value_text, type: coded_map(row)}

  defp decode(%{value_kind: "related_url"} = row),
    do: %{url: row.value_text, label: coded_map(row)}

  defp coded_map(%{coded_id: nil, coded_scheme: nil, coded_label: nil}), do: nil

  defp coded_map(row),
    do:
      %{id: row.coded_id, scheme: row.coded_scheme}
      |> maybe_put(:label, row.coded_label)
      |> compact()

  defp role_map(%{role_id: nil, role_scheme: nil, role_label: nil}), do: nil

  defp role_map(row),
    do:
      %{id: row.role_id, scheme: row.role_scheme}
      |> maybe_put(:label, row.role_label)
      |> compact()

  defp term_value(%{term_id: nil, term_label: label}), do: label
  defp term_value(%{term_id: id, term_label: nil}), do: %{id: id}
  defp term_value(%{term_id: id, term_label: label}), do: %{id: id, label: label}

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)

  defp compact(map), do: map |> Enum.reject(fn {_, v} -> is_nil(v) end) |> Map.new()

  defp map_value(%{} = map, key), do: Map.get(map, key) || Map.get(map, to_string(key))
  defp map_value(_, _key), do: nil
end
