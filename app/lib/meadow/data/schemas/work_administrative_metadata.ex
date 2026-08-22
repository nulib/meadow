defmodule Meadow.Data.Schemas.WorkAdministrativeMetadata do
  @moduledoc """
  Administrative metadata for a Work. Coded fields and `project_cycle` live on
  the `work_administrative_metadata` row (one per work); the repeating
  `project_*` fields are `work_metadata_values` rows in the `administrative`
  section. See `Meadow.Data.Schemas.MetadataSchema` for what each kind generates.
  """

  use Meadow.Data.Schemas.MetadataSchema,
    table: "work_administrative_metadata",
    section: "administrative"

  metadata do
    coded(:library_unit)
    coded(:preservation_level)
    coded(:status)
    string(:project_cycle)
    values(:project_name)
    values(:project_desc)
    values(:project_proposer)
    values(:project_manager)
    values(:project_task_number)
  end

  @doc "Field names in the order the jsonb embed declared them (CSV export headers depend on it)"
  def field_names,
    do: [
      :library_unit,
      :preservation_level,
      :project_name,
      :project_desc,
      :project_proposer,
      :project_manager,
      :project_task_number,
      :project_cycle,
      :status
    ]
end
