defmodule Meadow.Utils.Ecto.Schema do
  @moduledoc """
  Utility functions for working with Ecto schemas, particularly for unrolling the schema into a more
  human-readable format.
  """

  alias Meadow.Data.Types

  @schemes %{
    # Field-specific schemes
    visibility: "visibility",
    work_type: "work_type",
    behavior: "behavior",
    descriptive_metadata: %{
      license: "license",
      rights_statement: "rights_statement",
      notes: %{type: "note_type"},
      related_url: %{label: "related_url"}
    },
    administrative_metadata: %{
      library_unit: "library_unit",
      preservation_level: "preservation_level",
      status: "status"
    },
    # Role schemes
    contributor: "marc_relator",
    subject: "subject_role"
  }

  @doc """
  Unrolls an Ecto schema into a map of field names to their types, recursively

  ## Options

    * `:read_only` - a list of fields to exclude from the unrolled schema. Can also be a keyword list where
                  the value is a list of fields to exclude from that field's schema.

  ## Examples

  iex> Meadow.Utils.Ecto.Schema.unroll(MyApp.MySchema)
  %{
    field1: "string",
    field2: "integer",
    embedded_field: %{
      subfield1: "string",
      subfield2: "integer"
    }
  }

  iex> Meadow.Utils.Ecto.Schema.unroll(MyApp.MySchema, read_only: [:field1])
  %{
    field1: "READ_ONLY",
    field2: "integer",
    embedded_field: %{
      subfield1: "string",
      subfield2: "integer"
    }
  }

  iex> Meadow.Utils.Ecto.Schema.unroll(MyApp.MySchema, read_only: [:embedded_field])
  %{
    field1: "string",
    field2: "integer",
    embedded_field: %{
      subfield1: "READ_ONLY",
      subfield2: "READ_ONLY"
    }
  }

  iex> Meadow.Utils.Ecto.Schema.unroll(MyApp.MySchema, read_only: [embedded_field: [:subfield1]])
  %{
    field1: "string",
    field2: "integer",
    embedded_field: %{
      subfield1: "READ_ONLY",
      subfield2: "integer"
    }
  }
  """
  def unroll(schema, opts \\ []) do
    opts = Keyword.validate!(opts, read_only: [])
    unroll_schema(schema, Map.new(opts))
  end

  # Storage bookkeeping columns on relational metadata rows that are not part of the value
  @hidden_fields [
    :work_id,
    :section,
    :field,
    :position,
    :role_scheme,
    :file_set_id,
    :extracted_metadata_id
  ]

  # Associations that are part of a schema's value shape (metadata rows)
  @value_associations [
    :descriptive_metadata,
    :administrative_metadata,
    :notes,
    :related_url,
    :date_created,
    :nav_place,
    :core_metadata,
    :structural_metadata,
    :derivatives,
    :extracted_metadata,
    :entries
  ]

  defp unroll_schema(schema, opts) do
    read_only = Map.get(opts, :read_only, [])
    parents = Map.get(opts, :parents, [])
    is_read_only = Map.get(opts, :is_read_only, false)

    fields =
      schema.__schema__(:fields)
      |> Enum.reject(&(&1 in @hidden_fields))
      |> Enum.map(fn field ->
        is_read_only = Enum.any?([is_read_only, Enum.member?(read_only, field)])

        unroll_field(schema, field, %{
          read_only: read_only,
          parents: parents,
          is_read_only: is_read_only
        })
      end)

    associations =
      schema.__schema__(:associations)
      |> Enum.filter(&value_association?(schema, &1))
      |> Enum.map(fn field ->
        is_read_only = Enum.any?([is_read_only, Enum.member?(read_only, field)])

        unroll_association(schema, field, %{
          read_only: read_only,
          parents: parents,
          is_read_only: is_read_only
        })
      end)

    (fields ++ associations)
    |> Enum.reject(&is_nil/1)
    |> Enum.into(%{})
  end

  defp value_association?(schema, field) do
    case schema.__schema__(:association, field) do
      %Ecto.Association.Has{related: related} ->
        field in @value_associations or metadata_row?(related)

      _ ->
        false
    end
  end

  defp metadata_row?(related),
    do:
      related in [Meadow.Data.Schemas.MetadataValue, Meadow.Data.Schemas.ControlledMetadataEntry]

  defp unroll_association(schema, field, %{
         read_only: read_only,
         parents: parents,
         is_read_only: is_read_only
       }) do
    read_only = nested_read_only(read_only, field)

    %Ecto.Association.Has{cardinality: cardinality, related: related} =
      schema.__schema__(:association, field)

    opts = %{read_only: read_only, parents: [field | parents], is_read_only: is_read_only}

    {field, unroll_related(related, cardinality, opts)}
  end

  defp unroll_related(_related, :many, %{is_read_only: true}), do: "READ_ONLY"
  defp unroll_related(related, :one, opts), do: unroll_schema(related, opts)

  defp unroll_related(Meadow.Data.Schemas.DateCreatedEntry, :many, _opts),
    do: [%{id: "UUID", edtf: "valid EDTF date string"}]

  defp unroll_related(related, :many, opts), do: [unroll_schema(related, opts)]

  defp nested_read_only(read_only, field) do
    case Keyword.get(read_only, field) do
      value when is_list(value) -> value
      _ -> []
    end
  end

  defp unroll_field(schema, field, %{
         read_only: read_only,
         parents: parents,
         is_read_only: is_read_only
       }) do
    read_only = nested_read_only(read_only, field)
    opts = %{read_only: read_only, parents: [field | parents], is_read_only: is_read_only}

    case schema.__schema__(:type, field) do
      {:parameterized, {Ecto.Embedded, %{cardinality: :one, related: related}}} ->
        {field, unroll_schema(related, opts)}

      {:parameterized, {Ecto.Embedded, %{cardinality: :many, related: related}}} ->
        {field, [unroll_schema(related, opts)]}

      type ->
        {field, unroll_type(type, field, parents)} |> maybe_read_only(is_read_only)
    end
  end

  defp unroll_field(:binary_id, _, _), do: "UUID"
  defp unroll_field(:utc_datetime, _, _), do: "utc_datetime (second precision)"
  defp unroll_field(:utc_datetime_usec, _, _), do: "utc_datetime (microsecond precision)"
  defp unroll_field(Elixir.Ecto.UUID, _, _), do: "UUID"
  defp unroll_field(Types.EDTFDate, _, _), do: "valid EDTF date string"
  defp unroll_field(Types.CodedTerm, field, parents), do: unroll_coded_term(field, parents)
  defp unroll_field(Types.ControlledTerm, _, _), do: %{id: "URI", label: "string"}
  defp unroll_field(type, _, _), do: to_string(type)

  defp unroll_type({:parameterized, {Types.CodedTerm, %{scheme: scheme}}}, _field, _parents)
       when is_binary(scheme),
       do: coded_term_spec(scheme)

  defp unroll_type({:parameterized, {Types.CodedTerm, _}}, field, parents),
    do: unroll_coded_term(field, parents)

  defp unroll_type({:array, type}, field, parents), do: [unroll_field(type, field, parents)]
  defp unroll_type(type, field, parents), do: unroll_field(type, field, parents)

  defp unroll_coded_term(:role, [parent | _]) do
    case @schemes[parent] do
      nil -> nil
      scheme -> coded_term_spec(scheme)
    end
  end

  defp unroll_coded_term(field, parents) do
    case get_in(@schemes, Enum.reverse([field | parents])) do
      nil -> nil
      scheme -> coded_term_spec(scheme)
    end
  end

  defp coded_term_spec(scheme),
    do: %{
      id: "(valid id for scheme `#{scheme}`)",
      label: "(valid label for scheme `#{scheme}`)",
      scheme: scheme
    }

  defp maybe_read_only({field, _value}, true), do: {field, "READ_ONLY"}
  defp maybe_read_only({field, value}, false), do: {field, value}
end
