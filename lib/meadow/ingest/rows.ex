defmodule Meadow.Ingest.Rows do
  import Ecto.Query, warn: false
  alias Meadow.Ingest.Notifications
  alias Meadow.Ingest.Schemas.Row
  alias Meadow.Repo

  @moduledoc """
  Secondary Context for Rows
  """

  @doc """
  Changes the validation state of a Row
  """
  def change_ingest_sheet_row_validation_state(
        %Row{} = ingest_sheet_row,
        %{state: "fail", errors: errors}
      ) do
    ingest_sheet_row
    |> Row.state_changeset(%{state: "fail", errors: errors})
    |> Repo.update()
    |> Notifications.ingest_sheet_validation()
  end

  @doc """
  Changes the validation state of a Row
  """
  def change_ingest_sheet_row_validation_state(%Row{} = ingest_sheet_row, state) do
    ingest_sheet_row
    |> Row.state_changeset(%{state: state})
    |> Repo.update()
    |> Notifications.ingest_sheet_validation()
  end

  @doc """
  Returns the list of ingest_sheet_rows matching a set of criteria.

  ## Examples

      iex> list_ingest_sheet_rows(ingest_sheet: %Sheet{})
      [%Row{}, ...]

      iex> list_ingest_sheet_rows(ingest_sheet: %Sheet{}, state: ["error"])
      [%Row{}, ...]
  """
  def list_ingest_sheet_rows(criteria) do
    criteria
    |> Enum.reduce(Row, &row_criteria/2)
    |> order_by(asc: :row)
    |> Repo.all()
  end

  defp row_criteria({:sheet, sheet}, query),
    do: row_criteria({:sheet_id, sheet.id}, query)

  defp row_criteria({:sheet_id, sheet_id}, query),
    do: from(r in query, where: r.sheet_id == ^sheet_id)

  defp row_criteria({:state, state}, query),
    do: from(r in query, where: r.state in ^state)

  defp row_criteria({:start, start}, query),
    do: from(r in query, where: r.row >= ^start)

  defp row_criteria({:limit, limit}, query), do: from(r in query, limit: ^limit)
end
