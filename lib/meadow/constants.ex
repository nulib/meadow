defmodule Meadow.Constants do
  @moduledoc false

  defmacro __using__(_) do
    quote do
      @ingest_sheet_headers ~w(accession_number description filename  label role work_accession_number)
      @role_priority ~w[Administrators Managers Editors Users]
    end
  end
end
