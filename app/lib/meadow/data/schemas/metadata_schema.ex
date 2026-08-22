defmodule Meadow.Data.Schemas.MetadataSchema do
  @moduledoc """
  Declarative definition of a per-work metadata row and its repeating child rows.

  A metadata module declares each field once, with its kind, and this module
  derives the Ecto schema, the changeset and a reflection function from that
  single declaration:

      defmodule Meadow.Data.Schemas.WorkExampleMetadata do
        use Meadow.Data.Schemas.MetadataSchema,
          table: "work_example_metadata",
          section: "example"

        metadata do
          string :title
          coded :license
          values :abstract
          controlled :contributor, role_required: true
          entries :notes, Meadow.Data.Schemas.NoteEntry
        end
      end

  Field kinds and what they generate:

    * `string name` - a `:string` column on the metadata row
    * `coded name` - a `Meadow.Data.Types.CodedTerm` column whose scheme is the
      field name and whose database column is `name_id`
    * `values name` - a `has_many` of `Meadow.Data.Schemas.MetadataValue` rows
      filtered to `section`/`field`
    * `controlled name, role_required: boolean` - a `has_many` of
      `Meadow.Data.Schemas.ControlledMetadataEntry` rows filtered to `field`
    * `entries name, schema` - a `has_many` of `schema` rows (one table per
      field); `schema` must define `changeset/3`, `natural_key/1` and
      `to_params/1`

  Every `has_many` is ordered by `position` and uses `on_replace: :delete`;
  `Meadow.Data.Schemas.MultiValued.cast_entries/3` handles the casting.

  Generated functions:

    * `changeset/2`
    * `__metadata__/1` and `__metadata__/2`
    * `permitted/0` - column fields (`string` and `coded`)
    * `repeating_fields/0` - every child-row field; also the preload list
    * `values/2` - plain string values of a `values` field

  Reflection:

      __metadata__(:section)          # "example"
      __metadata__(:fields)           # every field, in declaration order
      __metadata__(:fields, :values)  # fields of one kind
      __metadata__(:fields, {:entries, NoteEntry})  # entries fields of one schema
      __metadata__(:kind, :abstract)  # :values (nil for unknown fields)
      __metadata__(:schema, :notes)   # NoteEntry (nil for column fields)
      __metadata__(:options, :contributor)  # [role_required: true]
  """

  import Ecto.Changeset
  alias Meadow.Data.Schemas.{ControlledMetadataEntry, MetadataSchema, MetadataValue, MultiValued}

  @kinds [:string, :coded, :values, :controlled, :entries]
  @column_kinds [:string, :coded]
  @row_kinds [:values, :controlled, :entries]

  def kinds, do: @kinds
  def column_kinds, do: @column_kinds
  def row_kinds, do: @row_kinds

  defmacro __using__(opts) do
    quote do
      use Ecto.Schema
      import Ecto.Changeset
      import Meadow.Data.Schemas.MetadataSchema, only: [metadata: 1]

      Module.register_attribute(__MODULE__, :metadata_fields, accumulate: true)
      @metadata_table Keyword.fetch!(unquote(opts), :table)
      @metadata_section Keyword.fetch!(unquote(opts), :section)
      @metadata_defined false
      @before_compile Meadow.Data.Schemas.MetadataSchema
    end
  end

  @doc "Declare the fields and build the Ecto schema from them"
  defmacro metadata(do: block) do
    quote do
      import Meadow.Data.Schemas.MetadataSchema,
        only: [string: 1, coded: 1, values: 1, controlled: 1, controlled: 2, entries: 2]

      unquote(block)

      import Meadow.Data.Schemas.MetadataSchema, only: [metadata: 1]

      @metadata_defined true
      @metadata_declared Enum.reverse(@metadata_fields)

      @primary_key false
      @foreign_key_type Ecto.UUID
      @timestamps_opts [type: :utc_datetime_usec]
      schema @metadata_table do
        belongs_to(:work, Meadow.Data.Schemas.Work, primary_key: true)

        Enum.each(@metadata_declared, fn {name, kind, opts} ->
          MetadataSchema.__define__(
            __MODULE__,
            @metadata_section,
            name,
            kind,
            opts
          )
        end)

        timestamps()
      end
    end
  end

  defmacro string(name), do: declare(name, :string, [])
  defmacro coded(name), do: declare(name, :coded, [])
  defmacro values(name), do: declare(name, :values, [])

  defmacro controlled(name, opts \\ []),
    do: declare(name, :controlled, Keyword.take(opts, [:role_required]))

  defmacro entries(name, schema), do: declare(name, :entries, schema: schema)

  defp declare(name, kind, opts) when is_atom(name) do
    quote do
      MetadataSchema.__check_unique__(__MODULE__, unquote(name))
      @metadata_fields {unquote(name), unquote(kind), unquote(opts)}
    end
  end

  @doc false
  def __check_unique__(module, name) do
    if Enum.any?(Module.get_attribute(module, :metadata_fields), &(elem(&1, 0) == name)),
      do: raise(ArgumentError, "metadata field #{inspect(name)} is declared twice")
  end

  # Runs inside the `schema` block, so Ecto.Schema's field/has_many helpers
  # are called through their underlying functions.
  @doc false
  def __define__(module, _section, name, :string, _opts),
    do: Ecto.Schema.__field__(module, name, :string, [])

  def __define__(module, _section, name, :coded, _opts),
    do:
      Ecto.Schema.__field__(module, name, Meadow.Data.Types.CodedTerm,
        scheme: to_string(name),
        source: :"#{name}_id"
      )

  def __define__(module, section, name, :values, _opts),
    do:
      has_many(module, name, MetadataValue,
        where: [section: section, field: to_string(name)],
        defaults: [section: section, field: to_string(name)]
      )

  def __define__(module, _section, name, :controlled, _opts),
    do:
      has_many(module, name, ControlledMetadataEntry,
        where: [field: to_string(name)],
        defaults: [field: to_string(name)]
      )

  def __define__(module, _section, name, :entries, opts),
    do: has_many(module, name, Keyword.fetch!(opts, :schema), [])

  defp has_many(module, name, schema, opts) do
    Ecto.Schema.__has_many__(
      module,
      name,
      schema,
      Keyword.merge(opts,
        foreign_key: :work_id,
        references: :work_id,
        preload_order: [asc: :position],
        on_replace: :delete
      )
    )
  end

  defmacro __before_compile__(env) do
    unless Module.get_attribute(env.module, :metadata_defined) do
      raise ArgumentError,
            "#{inspect(env.module)} uses MetadataSchema but has no `metadata do ... end` block"
    end

    declared = Module.get_attribute(env.module, :metadata_declared)
    generated_functions(for {name, :values, _} <- declared, do: name)
  end

  defp generated_functions(values_fields) do
    quote do
      @doc "Column fields cast directly on the metadata row"
      def permitted, do: __metadata__(:permitted)

      @doc "Every repeating (child-row) field; also the preload list"
      def repeating_fields, do: __metadata__(:repeating)

      @doc "Reflection over the declared fields (see `Meadow.Data.Schemas.MetadataSchema`)"
      def __metadata__(:section), do: @metadata_section

      def __metadata__(key),
        do: MetadataSchema.reflect(@metadata_declared, key)

      def __metadata__(key, arg),
        do: MetadataSchema.reflect(@metadata_declared, key, arg)

      def changeset(metadata, params),
        do: MetadataSchema.cast_metadata(__MODULE__, metadata, params)

      @doc "Plain string values of a repeating free-text field"
      def values(%__MODULE__{} = metadata, field) when field in unquote(values_fields),
        do: metadata |> Map.get(field) |> MetadataValue.values()

      def values(nil, _field), do: []
    end
  end

  @doc false
  def reflect(declared, :fields), do: Enum.map(declared, &elem(&1, 0))

  def reflect(declared, :permitted),
    do: for({name, kind, _} <- declared, kind in @column_kinds, do: name)

  def reflect(declared, :repeating),
    do: for({name, kind, _} <- declared, kind in @row_kinds, do: name)

  @doc false
  def reflect(declared, :fields, {:entries, schema}),
    do: for({name, :entries, schema: ^schema} <- declared, do: name)

  def reflect(declared, :fields, kind) when kind in @kinds,
    do: for({name, ^kind, _} <- declared, do: name)

  def reflect(declared, :kind, field),
    do: declared |> find_field(field) |> maybe_elem(1)

  def reflect(declared, :options, field),
    do: declared |> find_field(field) |> maybe_elem(2)

  def reflect(declared, :schema, field) do
    case find_field(declared, field) do
      {_, :values, _} -> MetadataValue
      {_, :controlled, _} -> ControlledMetadataEntry
      {_, :entries, opts} -> Keyword.fetch!(opts, :schema)
      _ -> nil
    end
  end

  defp find_field(declared, field), do: Enum.find(declared, &(elem(&1, 0) == field))

  defp maybe_elem(nil, _index), do: nil
  defp maybe_elem(tuple, index), do: elem(tuple, index)

  @doc "The child-row schema backing a repeating field (nil for column fields)"
  def entry_schema(module, field), do: module.__metadata__(:schema, field)

  @doc "Cast the column fields, then every repeating field through `MultiValued.cast_entries/3`"
  def cast_metadata(module, metadata, params) do
    changeset = cast(metadata, params, module.__metadata__(:permitted))

    Enum.reduce(module.__metadata__(:repeating), changeset, fn field, acc ->
      MultiValued.cast_entries(acc, field, cast_options(module, field))
    end)
  end

  defp cast_options(module, field) do
    schema = entry_schema(module, field)

    [
      with: changeset_fun(module, field, schema),
      key: key_fun(schema),
      normalize: &schema.to_params/1
    ]
  end

  defp changeset_fun(module, field, ControlledMetadataEntry) do
    if module.__metadata__(:options, field)[:role_required],
      do: &ControlledMetadataEntry.changeset_with_role/3,
      else: &ControlledMetadataEntry.changeset/3
  end

  defp changeset_fun(_module, _field, schema), do: &schema.changeset/3

  defp key_fun(MetadataValue), do: &MetadataValue.value/1
  defp key_fun(schema), do: &schema.natural_key/1
end
