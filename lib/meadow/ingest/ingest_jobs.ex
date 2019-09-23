defmodule Meadow.Ingest.IngestSheets do
  @moduledoc """
  Secondary Context for IngestSheets
  """

  import Ecto.Query, warn: false
  alias Meadow.Ingest.IngestSheets.{IngestSheet, IngestSheetRow}
  alias Meadow.Repo
  alias Meadow.Utils.MapList

  @doc """
  Returns the list of ingest_sheets in a project.

  ## Examples

      iex> list_ingest_sheets()
      [%Job{}, ...]

  """
  def list_ingest_sheets(project) do
    IngestSheet
    |> where([ingest_sheet], ingest_sheet.project_id == ^project.id)
    |> Repo.all()
  end

  @doc """
  Returns the list of all ingest_sheets in all projects.
  ## Examples
      iex> list_all_ingest_sheets()
      [%Job{}, ...]
  """
  def list_all_ingest_sheets do
    IngestSheet
    |> Repo.all()
  end

  @doc """
  Gets a single sheet.

  Raises `Ecto.NoResultsError` if the Job does not exist.

  ## Examples

      iex> get_sheet!(123)
      %Job{}

      iex> get_sheet!(456)
      ** (Ecto.NoResultsError)

  """
  def get_ingest_sheet!(id) do
    IngestSheet
    |> Repo.get!(id)
  end

  @doc """
  Gets an ingest sheet with its project preloaded
  """

  def get_ingest_sheet_with_project!(id) do
    IngestSheet
    |> where([ingest_sheet], ingest_sheet.id == ^id)
    |> preload(:project)
    |> Repo.one()
  end

  @doc """
  Gets the list of states for a single sheet.

  ## Examples

      iex> get_sheet_state(123)
      [
        %{ name: "overall", value: "pending" }
      ]
  """
  def get_sheet_state(id) do
    IngestSheet
    |> select([sheet], sheet.state)
    |> where([sheet], sheet.id == ^id)
    |> Repo.one()
  end

  @doc """
  Retrieves aggregate completion statistics for one or more ingest sheets.
  """
  def get_sheet_progress(id) when is_binary(id), do: Map.get(get_sheet_progress([id]), id)

  def get_sheet_progress(ids) when is_list(ids) do
    result = list_ingest_sheet_row_counts(ids)

    tally = fn %{state: state, count: count}, acc ->
      if state === "pending", do: acc, else: count + acc
    end

    update_state = fn {id, states} ->
      total = states |> Enum.reduce(0, fn %{count: count}, acc -> acc + count end)
      complete = states |> Enum.reduce(0, tally)
      pct = complete / total * 100
      {id, %{states: states, total: total, percent_complete: pct}}
    end

    ids
    |> Enum.map(fn id ->
      {id, %{states: [], total: 0, percent_complete: 0.0}}
    end)
    |> Enum.into(%{})
    |> Map.merge(
      result
      |> Enum.map(update_state)
      |> Enum.into(%{})
    )
  end

  @doc """
  Creates a sheet.

  ## Examples

      iex> create_ingest_sheet_row(%{field: value})
      {:ok, %Job{}}

      iex> create_ingest_sheet_row(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_ingest_sheet(attrs \\ %{}) do
    %IngestSheet{}
    |> IngestSheet.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Changes the state of an IngestSheet Event
  """
  def change_ingest_sheet_state(%IngestSheet{} = ingest_sheet, updates) do
    new_state =
      get_sheet_state(ingest_sheet.id)
      |> MapList.merge(:name, :state, updates)
      |> Enum.map(fn
        %IngestSheet.State{} = m -> Map.from_struct(m)
        other -> other
      end)

    ingest_sheet
    |> IngestSheet.changeset(%{state: new_state})
    |> Repo.update()
    |> send_ingest_sheet_notification()
  end

  def change_ingest_sheet_state!(%IngestSheet{} = ingest_sheet, updates) do
    case change_ingest_sheet_state(ingest_sheet, updates) do
      {:ok, result} -> result
      {:error, error} -> raise error
    end
  end

  @doc """
  Updates a sheet.

  ## Examples
      iex> update_sheet(sheet, %{field: new_value})
      {:ok, %Job{}}

      iex> update_sheet(sheet, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_ingest_sheet(%IngestSheet{} = ingest_sheet, attrs) do
    ingest_sheet
    |> IngestSheet.changeset(attrs)
    |> Repo.update()
    |> send_ingest_sheet_notification()
  end

  @doc """
  Deletes a Job.

  ## Examples

      iex> delete_sheet(sheet)
      {:ok, %Job{}}

      iex> delete_sheet(sheet)
      {:error, %Ecto.Changeset{}}

  """
  def delete_ingest_sheet(%IngestSheet{} = ingest_sheet) do
    Repo.delete(ingest_sheet)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking sheet changes.

  ## Examples

      iex> change_sheet(sheet)
      %Ecto.Changeset{source: %Job{}}

  """
  def change_ingest_sheet(%IngestSheet{} = sheet) do
    IngestSheet.changeset(sheet, %{})
  end

  @doc """
  Add error  m

  """
  def add_error(%IngestSheet{} = sheet, error) do
    from(j in IngestSheet, where: j.id == ^sheet.id)
    |> Repo.update_all(push: [file_errors: error])
  end

  @doc """
  Returns row counts for one or more IngestSheets grouped by state
  """
  def list_ingest_sheet_row_counts(ids) when is_list(ids) do
    aggregate = fn rows ->
      rows |> Enum.map(fn [_sheet_id, state, count] -> %{state: state, count: count} end)
    end

    ids = ids |> Enum.uniq()

    IngestSheetRow
    |> select([row], [row.ingest_sheet_id, row.state, count(row)])
    |> where([row], row.ingest_sheet_id in ^ids)
    |> group_by([row], [row.ingest_sheet_id, row.state])
    |> order_by([row], asc: row.ingest_sheet_id, asc: row.state)
    |> Meadow.Repo.all()
    |> Enum.chunk_by(fn [sheet_id, _, _] -> [sheet_id] end)
    |> Enum.map(fn rows ->
      {
        rows |> List.first() |> List.first(),
        aggregate.(rows)
      }
    end)
    |> Enum.into(%{})
  end

  def list_ingest_sheet_row_counts(sheet_id) when is_binary(sheet_id) do
    case Map.get(list_ingest_sheet_row_counts([sheet_id]), sheet_id) do
      nil -> []
      other -> other
    end
  end

  def list_ingest_sheet_row_counts(%IngestSheet{} = sheet) do
    list_ingest_sheet_row_counts(sheet.id)
  end

  @doc """
  Returns the list of ingest_sheet_rows matching a set of criteria.

  ## Examples

      iex> list_ingest_sheet_rows(ingest_sheet: %Job{})
      [%IngestSheetRow{}, ...]

      iex> list_ingest_sheet_rows(ingest_sheet: %Job{}, state: ["error"])
      [%IngestSheetRow{}, ...]
  """
  def list_ingest_sheet_rows(criteria) do
    criteria
    |> Enum.reduce(IngestSheetRow, fn
      {:sheet, sheet}, query ->
        from(r in query)
        |> where([ingest_sheet_row], ingest_sheet_row.ingest_sheet_id == ^sheet.id)

      {:sheet_id, sheet_id}, query ->
        from(r in query)
        |> where([ingest_sheet_row], ingest_sheet_row.ingest_sheet_id == ^sheet_id)

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

  @doc """
  Changes the state of an IngestSheetRow
  """
  def change_ingest_sheet_row_state(%IngestSheetRow{} = ingest_sheet_row, state) do
    ingest_sheet_row
    |> IngestSheetRow.state_changeset(%{state: state})
    |> Repo.update()
    |> send_ingest_sheet_row_notification()
  end

  @doc """
  Updates an ingest row.

  ## Examples
      iex> update_ingest_sheet_row(row, %{field: new_value})
      {:ok, %IngestSheetRow{}}

      iex> update_ingest_sheet_row(row, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_ingest_sheet_row(%IngestSheetRow{} = ingest_sheet_row, attrs) do
    ingest_sheet_row
    |> IngestSheetRow.changeset(attrs)
    |> Repo.update()
    |> send_ingest_sheet_row_notification()
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking sheet changes.

  ## Examples

      iex> change_ingest_sheet_row(row)
      %Ecto.Changeset{source: %Row{}}

  """
  def change_ingest_sheet_row(%IngestSheetRow{} = row) do
    IngestSheetRow.changeset(row, %{})
  end

  # Absinthe Notifications

  defp send_ingest_sheet_notification({:ok, sheet}),
    do: {:ok, send_ingest_sheet_notification(sheet)}

  defp send_ingest_sheet_notification(%IngestSheet{} = sheet) do
    Absinthe.Subscription.publish(
      MeadowWeb.Endpoint,
      sheet,
      ingest_sheet_update: "sheet:" <> sheet.id
    )

    sheet
  end

  defp send_ingest_sheet_notification(other), do: other

  defp send_ingest_sheet_row_notification({:ok, row}),
    do: {:ok, send_ingest_sheet_row_notification(row)}

  defp send_ingest_sheet_row_notification(%IngestSheetRow{} = row) do
    topic = Enum.join(["row", row.ingest_sheet_id, row.state], ":")

    Absinthe.Subscription.publish(
      MeadowWeb.Endpoint,
      row,
      ingest_sheet_row_state_update: topic
    )

    Absinthe.Subscription.publish(
      MeadowWeb.Endpoint,
      row,
      ingest_sheet_row_update: Enum.join(["row", row.ingest_sheet_id], ":")
    )

    Absinthe.Subscription.publish(
      MeadowWeb.Endpoint,
      get_sheet_progress(row.ingest_sheet_id),
      ingest_sheet_progress_update: Enum.join(["progress", row.ingest_sheet_id], ":")
    )

    row
  end

  defp send_ingest_sheet_row_notification(other), do: other
end
