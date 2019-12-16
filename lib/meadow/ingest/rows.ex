defmodule Meadow.Ingest.Rows do
  alias Meadow.Ingest.Schemas.Row
  alias Meadow.Ingest.Notifications
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
    |> Notifications.send_ingest_sheet_row_notification()
  end

  @doc """
  Changes the state of a Row
  """
  def change_ingest_sheet_row_state(%Row{} = ingest_sheet_row, state) do
    ingest_sheet_row
    |> Row.state_changeset(%{state: state})
    |> Repo.update()
    |> Notifications.send_ingest_sheet_row_notification()
  end
end
