defmodule Meadow.Ingest.Actions.UpdateIngestSheetStatus do
  @moduledoc """
  Action to update the status of an IngestSheet during
  the processing of a FileSet.

  Subscribes to:
  * All errors
  * Final topic of FileSet pipeline

  Filter:
  context: "ingest_sheet"
  """
  alias Meadow.Ingest.IngestSheets
  alias Sequins.Pipeline.Action
  use Action
  require Logger

  @actiondoc "Update IngestSheet Status"

  def process(
        _data,
        %{
          ingest_sheet: ingest_sheet_id,
          ingest_sheet_row: row,
          process: last_action,
          status: status
        }
      ) do
    Logger.info(
      "Setting status #{status} on row #{row} of sheet #{ingest_sheet_id} from #{last_action}"
    )

    {result, _} =
      IngestSheets.update_ingest_status(
        ingest_sheet_id,
        String.to_integer(row),
        status
      )

    result
  end

  def process(d, a) do
    Logger.warn("We should never get here! data=#{inspect(d)} attributes=#{inspect(a)}")
    :ok
  end
end
