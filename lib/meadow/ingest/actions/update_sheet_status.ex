defmodule Meadow.Ingest.Actions.UpdateSheetStatus do
  @moduledoc """
  Action to update the status of an Sheet during
  the processing of a FileSet.

  Subscribes to:
  * All errors
  * Final topic of FileSet pipeline

  Filter:
  context: "ingest_sheet"
  """
  alias Meadow.Ingest.{Sheets, Status}
  alias Sequins.Pipeline.Action
  use Action
  require Logger

  @actiondoc "Update Sheet Status"

  def process(
        _data,
        %{
          ingest_sheet: sheet_id,
          ingest_sheet_row: row,
          process: last_action,
          status: status
        }
      ) do
    Logger.info("Setting status #{status} on row #{row} of sheet #{sheet_id} from #{last_action}")

    {result, _} =
      Status.update_status(
        sheet_id,
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
