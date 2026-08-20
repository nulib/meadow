defmodule Meadow.Data.Schemas.WorkAdministrativeMetadata do
  @moduledoc """
  Administrative metadata for a Work. Scalar and coded fields live on the
  `work_administrative_metadata` row (one per work); the repeating `project_*`
  fields are `work_metadata_values` rows in the `administrative` section.
  """

  import Ecto.Changeset
  use Ecto.Schema
  alias Meadow.Data.Schemas.{MetadataValue, MultiValued, Work}
  alias Meadow.Data.Types

  @coded_fields [:library_unit, :preservation_level, :status]
  @scalar_fields [:project_cycle]
  @multi_valued_fields [
    :project_name,
    :project_desc,
    :project_proposer,
    :project_manager,
    :project_task_number
  ]

  @primary_key false
  @foreign_key_type Ecto.UUID
  @timestamps_opts [type: :utc_datetime_usec]
  schema "work_administrative_metadata" do
    belongs_to(:work, Work, primary_key: true)

    @coded_fields
    |> Enum.each(fn f ->
      field f, Types.CodedTerm, scheme: to_string(f), source: :"#{f}_id"
    end)

    field :project_cycle, :string

    @multi_valued_fields
    |> Enum.each(fn f ->
      has_many f, MetadataValue,
        foreign_key: :work_id,
        references: :work_id,
        where: [section: "administrative", field: to_string(f)],
        defaults: [section: "administrative", field: to_string(f)],
        preload_order: [asc: :position],
        on_replace: :delete
    end)

    timestamps()
  end

  def changeset(metadata, params) do
    changeset = cast(metadata, params, permitted())

    Enum.reduce(@multi_valued_fields, changeset, fn field, acc ->
      MultiValued.cast_entries(acc, field,
        with: &MetadataValue.changeset/3,
        key: &MetadataValue.value/1,
        normalize: &MetadataValue.to_params/1
      )
    end)
  end

  def permitted, do: @coded_fields ++ @scalar_fields

  @doc "Field names in the order the jsonb embed declared them (CSV export headers depend on it)"
  def field_names,
    do: [:library_unit, :preservation_level] ++ @multi_valued_fields ++ [:project_cycle, :status]

  def scalar_fields, do: @scalar_fields
  def coded_fields, do: @coded_fields
  def multi_valued_fields, do: @multi_valued_fields
  def repeating_fields, do: @multi_valued_fields
  def preloads, do: @multi_valued_fields

  def values(%__MODULE__{} = metadata, field) when field in @multi_valued_fields,
    do: metadata |> Map.get(field) |> MetadataValue.values()

  def values(nil, _field), do: []
end
