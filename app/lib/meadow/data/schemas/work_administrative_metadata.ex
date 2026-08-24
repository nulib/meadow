defmodule Meadow.Data.Schemas.WorkAdministrativeMetadata do
  @moduledoc """
  Administrative metadata for a Work. Everything lives on the
  `work_administrative_metadata` row (one per work): coded terms and
  `project_cycle` as columns, the repeating `project_*` fields as `text[]`.

  Fields are declared in CSV export header order; see
  `Meadow.Data.Schemas.MetadataSchema` for what each kind generates.
  """

  use Meadow.Data.Schemas.MetadataSchema,
    table: "work_administrative_metadata",
    section: "administrative"

  metadata do
    coded(:library_unit)
    coded(:preservation_level)

    values(:project_name)
    values(:project_desc)
    values(:project_proposer)
    values(:project_manager)
    values(:project_task_number)

    string(:project_cycle)

    coded(:status)
  end
end
