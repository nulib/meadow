defmodule Meadow.Ingest.Status do
  @moduledoc """
  Primary context for Ingest Status
  """

  import Ecto.Query, warn: false
  alias Meadow.Ingest.Schemas.{Row, Sheet, Status}
  alias Meadow.Ingest.Sheets
  alias Meadow.Repo

  @doc """
  Update the ingest status of an ingest sheet or a row
  """
  def change(%Sheet{id: sheet_id}),
    do: change(sheet_id)

  def change(sheet_id) do
    states =
      from(entry in Status,
        distinct: true,
        select: entry.status,
        where: entry.sheet_id == ^sheet_id and entry.row > 0
      )
      |> Repo.all()
      |> Enum.into(%MapSet{})

    status =
      if MapSet.size(MapSet.intersection(states, MapSet.new(["pending", nil]))) == 0,
        do: "finished",
        else: "pending"

    status_text =
      if MapSet.member?(states, "error"),
        do: "#{status} (with errors)",
        else: status

    Repo.transaction(fn ->
      if status == "finished" do
        Sheets.get_ingest_sheet!(sheet_id)
        |> Sheets.update_ingest_sheet_status("completed")
      end

      %Status{
        sheet_id: sheet_id
      }
      |> Status.changeset(%{status: status_text})
      |> Repo.insert(
        on_conflict: [set: [status: status_text]],
        conflict_target: [:sheet_id, :row]
      )
    end)
  end

  def change(%Row{} = row, ingest_status),
    do: change(row.sheet_id, row.row, ingest_status)

  def change(sheet_id, row, ingest_status) do
    case %Status{sheet_id: sheet_id, row: row}
         |> Status.changeset(%{
           status: ingest_status
         })
         |> Repo.insert(
           on_conflict: [set: [status: ingest_status]],
           conflict_target: [:sheet_id, :row]
         ) do
      {:ok, _} -> change(sheet_id)
      other -> other
    end
  end
end
