defmodule Meadow.Constants do
  @moduledoc false

  defmacro __using__(_) do
    quote do
      @work_types ~w[image audio video document]
      @ingest_statuses ~w[pending processing complete error]
      @visibility ~w[open authenticated restricted]
      @default_visibility "restricted"
      @file_set_roles ~w[am pm]
      @ingest_sheet_headers ~w(accession_number description filename role work_accession_number)
      @role_priority ~w[Administrators Managers Editors Users]
    end
  end
end
