defmodule Meadow.Ingest.Rows do
  import Ecto.Query, warn: false
  alias Meadow.Ingest.Notifications
  alias Meadow.Ingest.Schemas.Row
  alias Meadow.Repo

  @moduledoc """
  Secondary Context for Rows
  """

  @doc """
  Gets a row by id
  """
  def get_row(row_id) do
    Repo.get!(Row, row_id)
  end

  @doc """
  Gets a row by ingest sheet and row number
  """
  def get_row(sheet_id, row_num) do
    from(r in Row, where: r.sheet_id == ^sheet_id and r.row == ^row_num)
    |> Repo.one()
  end

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
  Get all of the rows needed to create and single work and all of its file sets
  """
  def get_rows_by_work_accession_number(sheet_id, work_accession_number) do
    # Query to unroll the array of fields into multiple rows with one field def each
    rows_with_fields =
      from(r in Row,
        select: %{r | single_field_pair: fragment("jsonb_array_elements(?.fields)", r)}
      )

    # Query to select only those rows from the above where the field header is
    # 'work_accession_number' and the value is the desired work_accession_number
    from(r in subquery(rows_with_fields),
      where:
        r.sheet_id == ^sheet_id and
          fragment(
            "?.single_field_pair->>'header' = 'work_accession_number' and ?.single_field_pair->>'value' = ?",
            r,
            r,
            ^work_accession_number
          ),
      order_by: r.row
    )
    |> Repo.all()
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
