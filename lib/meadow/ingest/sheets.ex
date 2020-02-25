defmodule Meadow.Ingest.Sheets do
  @moduledoc """
  API for Ingest Sheets
  """
  import Ecto.Query, warn: false
  alias Meadow.Data.Schemas.ActionState
  alias Meadow.Data.Schemas.FileSet
  alias Meadow.Data.Schemas.Work
  alias Meadow.Ingest.Notifications
  alias Meadow.Ingest.Schemas.{Project, Row, Sheet, SheetWorks}
  alias Meadow.Repo
  alias Meadow.Utils.MapList

  @doc """
  Creates a sheet.

  ## Examples

      iex> create_ingest_sheet_row(%{field: value})
      {:ok, %Sheet{}}

      iex> create_ingest_sheet_row(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_ingest_sheet(attrs \\ %{}) do
    %Sheet{}
    |> Sheet.changeset(attrs)
    |> Repo.insert()
    |> Notifications.ingest_sheet()
  end

  @doc """
  Updates a sheet.

  ## Examples
      iex> update_sheet(sheet, %{field: new_value})
      {:ok, %Sheet{}}

      iex> update_sheet(sheet, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_ingest_sheet(%Sheet{} = ingest_sheet, attrs) do
    ingest_sheet
    |> Sheet.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes an Sheet.
  Set the status to 'DELETED' and send a notification before deleting
  ## Examples

      iex> delete_sheet(sheet)
      {:ok, %Sheet{}}

      iex> delete_sheet(sheet)
      {:error, %Ecto.Changeset{}}

  """
  def delete_ingest_sheet(%Sheet{} = ingest_sheet) do
    with {:ok, ingest_sheet} <- update_ingest_sheet_status(ingest_sheet, "deleted") do
      ingest_sheet
      |> Repo.delete()
      |> Notifications.ingest_sheet()
    end
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking sheet changes.

  ## Examples

      iex> change_sheet(sheet)
      %Ecto.Changeset{source: %Sheet{}}

  """
  def change_ingest_sheet(%Sheet{} = sheet) do
    Sheet.changeset(sheet, %{})
  end

  @doc """
  Returns the list of ingest_sheets in a project.

  ## Examples

      iex> list_ingest_sheets()
      [%Sheet{}, ...]

  """
  def list_ingest_sheets(project) do
    Sheet
    |> where([ingest_sheet], ingest_sheet.project_id == ^project.id)
    |> Repo.all()
  end

  @doc """
  Returns the list of all ingest_sheets in all projects.
  ## Examples
      iex> list_all_ingest_sheets()
      [%Sheet{}, ...]
  """
  def list_all_ingest_sheets do
    Sheet
    |> Repo.all()
  end

  @doc """
  Gets a single sheet.

  Raises `Ecto.NoResultsError` if the Sheet does not exist.

  ## Examples

      iex> get_ingest_sheet!(123)
      %Sheet{}

      iex> get_ingest_sheet!(456)
      ** (Ecto.NoResultsError)

  """
  def get_ingest_sheet!(id) do
    Sheet
    |> Repo.get!(id)
  end

  @doc """
  Gets an ingest sheet with its project preloaded
  """

  def get_ingest_sheet_with_project!(id) do
    Sheet
    |> where([ingest_sheet], ingest_sheet.id == ^id)
    |> preload(:project)
    |> Repo.one()
  end

  @doc """
  Updates a sheet's status.

  ## Examples
      iex> update_ingest_sheet_status(sheet, %{status: "valid"})
      {:ok, %Sheet{}}

      iex> update_ingest_sheet_status(sheet, %{status: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_ingest_sheet_status(%Sheet{} = ingest_sheet, status) do
    ingest_sheet
    |> Sheet.status_changeset(%{status: status})
    |> Repo.update()
    |> Notifications.ingest_sheet()
  end

  def update_ingest_sheet_status({:ok, %Sheet{} = ingest_sheet}, status) do
    update_ingest_sheet_status(ingest_sheet, status)
  end

  @doc """
  Gets the list of states for a single sheet.

  ## Examples

      iex> get_sheet_validation_state(123)
      [
        %{ name: "overall", value: "pending" }
      ]
  """
  def get_sheet_validation_state(id) do
    Sheet
    |> select([sheet], sheet.state)
    |> where([sheet], sheet.id == ^id)
    |> Repo.one()
  end

  @doc """
  Retrieves aggregate completion statistics for the validation step of one or more ingest sheets.
  """
  def get_sheet_validation_progress(id) when is_binary(id),
    do: Map.get(get_sheet_validation_progress([id]), id)

  def get_sheet_validation_progress(ids) when is_list(ids) do
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
  Changes the validation state of an Sheet Event
  """
  def change_ingest_sheet_validation_state(%Sheet{} = ingest_sheet, updates) do
    new_state =
      get_sheet_validation_state(ingest_sheet.id)
      |> MapList.merge(:name, :state, updates)
      |> Enum.map(fn
        %Sheet.State{} = m -> Map.from_struct(m)
        other -> other
      end)

    ingest_sheet
    |> Sheet.changeset(%{state: new_state})
    |> Repo.update()
  end

  def change_ingest_sheet_validation_state!(%Sheet{} = ingest_sheet, updates) do
    case change_ingest_sheet_validation_state(ingest_sheet, updates) do
      {:ok, result} -> result
      {:error, error} -> raise error
    end
  end

  @doc """
  Add file level error message to ingest sheet's errors array

  ## Examples

  iex>  add_file_validation_errors_to_ingest_sheet(sheet, errors)
  {:ok, %Sheet{}}

  iex> add_file_validation_errors_to_ingest_sheet(sheet, errors)
  {:error, %Ecto.Changeset{}}
  """
  def add_file_validation_errors_to_ingest_sheet(%Sheet{} = ingest_sheet, errors) do
    ingest_sheet
    |> Sheet.file_errors_changeset(%{file_errors: ingest_sheet.file_errors ++ errors})
    |> Repo.update()
  end

  @doc """
  Returns row counts for one or more Sheets grouped by state
  """
  def list_ingest_sheet_row_counts(ids) when is_list(ids) do
    aggregate = fn rows ->
      rows |> Enum.map(fn [_sheet_id, state, count] -> %{state: state, count: count} end)
    end

    ids = ids |> Enum.uniq()

    Row
    |> select([row], [row.sheet_id, row.state, count(row)])
    |> where([row], row.sheet_id in ^ids)
    |> group_by([row], [row.sheet_id, row.state])
    |> order_by([row], asc: row.sheet_id, asc: row.state)
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

  def list_ingest_sheet_row_counts(%Sheet{} = sheet) do
    list_ingest_sheet_row_counts(sheet.id)
  end

  def list_ingest_sheet_works(%Sheet{} = ingest_sheet) do
    ingest_sheet
    |> Repo.preload(:works)
    |> Map.get(:works)
  end

  def list_ingest_sheet_works(sheet_id) do
    from(s in Meadow.Ingest.Schemas.Sheet,
      where: s.id == ^sheet_id,
      preload: :works
    )
    |> Repo.one()
    |> Map.get(:works)
  end

  def file_set_count(%Sheet{} = ingest_sheet), do: file_set_count(ingest_sheet.id)

  def file_set_count(sheet_id) do
    from(r in Row,
      where: r.sheet_id == ^sheet_id,
      select: count(r.sheet_id)
    )
    |> Repo.one()
  end

  def completed_file_set_count(%Sheet{} = ingest_sheet),
    do: completed_file_set_count(ingest_sheet.id)

  def completed_file_set_count(sheet_id) do
    from([entry: a] in file_set_action_states(sheet_id),
      where: a.outcome in ["ok", "error"],
      where: a.object_type == "Meadow.Data.Schemas.FileSet",
      where: a.action == "Meadow.Pipeline.Actions.FileSetComplete",
      select: count(a.id)
    )
    |> Repo.one()
  end

  def total_action_count(%Sheet{} = ingest_sheet), do: total_action_count(ingest_sheet.id)

  def total_action_count(sheet_id) do
    from([entry: a] in file_set_action_states(sheet_id),
      where: a.object_type == "Meadow.Data.Schemas.FileSet",
      select: count(a.id)
    )
    |> Repo.one()
  end

  def completed_action_count(%Sheet{} = ingest_sheet),
    do: completed_action_count(ingest_sheet.id)

  def completed_action_count(sheet_id) do
    from([entry: a] in file_set_action_states(sheet_id),
      where: a.object_type == "Meadow.Data.Schemas.FileSet",
      where: a.outcome in ["ok", "error"],
      select: count(a.id)
    )
    |> Repo.one()
  end

  def ingest_errors(%Sheet{} = ingest_sheet), do: ingest_errors(ingest_sheet.id)

  def ingest_errors(sheet_id) do
    row_errors =
      from([entry: entry, row: row] in row_action_states(sheet_id),
        where: entry.outcome in ["error", "skipped"],
        select: %{
          row_number: row.row,
          accession_number: row.file_set_accession_number,
          fields: row.fields,
          id: entry.object_id,
          action: entry.action,
          outcome: entry.outcome,
          errors: entry.notes
        }
      )

    file_set_errors =
      from([entry: entry, row: row] in file_set_action_states(sheet_id),
        where: entry.outcome in ["error", "skipped"],
        select: %{
          row_number: row.row,
          accession_number: row.file_set_accession_number,
          fields: row.fields,
          id: entry.object_id,
          action: entry.action,
          outcome: entry.outcome,
          errors: entry.notes
        }
      )

    query = from(row_errors, union_all: ^file_set_errors)

    from(q in subquery(query), order_by: q.row_number)
    |> Repo.all()
    |> Enum.map(fn error_row ->
      Map.merge(
        error_row,
        error_row.fields
        |> Enum.map(fn field ->
          {field.header |> String.to_atom(), field.value}
        end)
        |> Enum.into(%{})
      )
      |> Map.delete(:fields)
    end)
  end

  def row_action_states(sheet_id) do
    from(a in ActionState,
      as: :entry,
      join: r in Row,
      as: :row,
      on: r.id == a.object_id,
      where: r.sheet_id == ^sheet_id
    )
  end

  def file_set_action_states(sheet_id) do
    from(a in ActionState,
      as: :entry,
      join: f in FileSet,
      on: f.id == a.object_id,
      join: w in Work,
      on: w.id == f.work_id,
      join: iw in SheetWorks,
      on: iw.work_id == w.id,
      join: r in Row,
      as: :row,
      on:
        r.sheet_id == iw.sheet_id and
          r.file_set_accession_number == f.accession_number,
      where: iw.sheet_id == ^sheet_id
    )
  end

  @doc "Composable query to add sheet_name and project_name to works"
  def works_with_sheets(query \\ Work) do
    from w in query,
      left_join: sw in SheetWorks,
      on: w.id == sw.work_id,
      left_join: s in Sheet,
      on: sw.sheet_id == s.id,
      left_join: p in Project,
      on: s.project_id == p.id,
      select_merge: %{
        extra_index_fields: %{
          sheet: %{id: s.id, name: s.name},
          project: %{id: p.id, name: p.title}
        }
      }
  end
end
