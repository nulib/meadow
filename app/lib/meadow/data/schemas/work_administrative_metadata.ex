defmodule Meadow.Data.Schemas.WorkAdministrativeMetadata do
  @moduledoc """
  Administrative metadata embedded in Work records.
  """

  import Ecto.Changeset
  use Ecto.Schema
  alias Meadow.Data.Types

  @timestamps_opts [type: :utc_datetime_usec]
  embedded_schema do
    field :library_unit, Types.CodedTerm
    field :preservation_level, Types.CodedTerm
    field :project_name, {:array, :string}, default: []
    field :project_desc, {:array, :string}, default: []
    field :project_proposer, {:array, :string}, default: []
    field :project_manager, {:array, :string}, default: []
    field :project_task_number, {:array, :string}, default: []
    field :project_cycle, :string
    field :status, Types.CodedTerm

    timestamps()
  end

  def changeset(metadata, params) do
    metadata
    |> cast(params, [
      :library_unit,
      :preservation_level,
      :project_name,
      :project_desc,
      :project_proposer,
      :project_manager,
      :project_task_number,
      :project_cycle,
      :status
    ])
  end

  def field_names, do: __schema__(:fields) -- [:id, :inserted_at, :updated_at]
end
