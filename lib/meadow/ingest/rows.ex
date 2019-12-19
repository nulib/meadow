defmodule Meadow.Ingest.Rows do
  import Ecto.Query, warn: false
  alias Meadow.Ingest.Notifications
  alias Meadow.Ingest.Schemas.Row
  alias Meadow.Repo

  @moduledoc """
  Secondary Context for Rows
  """

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking sheet changes.

  ## Examples

      iex> change_ingest_sheet_row(row)
      %Ecto.Changeset{source: %Row{}}

  """
  def change_ingest_sheet_row(%Row{} = row) do
    Row.changeset(row, %{})
  end

  @doc """
  Updates an ingest row.

  ## Examples
      iex> update_ingest_sheet_row(row, %{field: new_value})
      {:ok, %Row{}}

      iex> update_ingest_sheet_row(row, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_ingest_sheet_row(%Row{} = ingest_sheet_row, attrs) do
    ingest_sheet_row
    |> Row.changeset(attrs)
    |> Repo.update()
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
  Returns the list of ingest_sheet_rows matching a set of criteria.

  ## Examples

      iex> list_ingest_sheet_rows(ingest_sheet: %Sheet{})
      [%Row{}, ...]

      iex> list_ingest_sheet_rows(ingest_sheet: %Sheet{}, state: ["error"])
      [%Row{}, ...]
  """
  def list_ingest_sheet_rows(criteria) do
    criteria
    |> Enum.reduce(Row, fn
      {:sheet, sheet}, query ->
        from(r in query)
        |> where([ingest_sheet_row], ingest_sheet_row.sheet_id == ^sheet.id)

      {:sheet_id, sheet_id}, query ->
        from(r in query)
        |> where([ingest_sheet_row], ingest_sheet_row.sheet_id == ^sheet_id)

      {:state, state}, query ->
        from(r in query) |> where([ingest_sheet_row], ingest_sheet_row.state in ^state)

      {:start, start}, query ->
        from(r in query) |> where([ingest_sheet_row], ingest_sheet_row.row >= ^start)

      {:limit, limit}, query ->
        from r in query, limit: ^limit

      _, query ->
        query
    end)
    |> order_by(asc: :row)
    |> Repo.all()
  end
end
