defmodule Meadow.Constants do
  @moduledoc false

  defmacro __using__(_) do
    quote do
      @ingest_sheet_headers ~w(description file_accession_number filename label
        role structure work_accession_number work_image work_type)
    end
  end
end
