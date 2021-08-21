defmodule Meadow.Ingest.Sheets do
  @moduledoc """
  API for Ingest Sheets
  """
  import Ecto.Query, warn: false
  alias Meadow.Data.Schemas.ActionState
  alias Meadow.Data.Schemas.FileSet
  alias Meadow.Data.Schemas.Work
  alias Meadow.Data.Works
  alias Meadow.Ingest.Schemas.{Progress, Project, Row, Sheet}
  alias Meadow.Repo
  alias Meadow.Utils.MapList

  require Logger

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
  Get an ingest sheet by its title

  ## Examples

    iex> get_ingest_sheet_by_title("sheet title")
    %Sheet{title: "sheet title"}

    iex> get_ingest_sheet_by_title("does not exist")
    nil
  """
  def get_ingest_sheet_by_title(title) do
    from(s in Sheet, where: s.title == ^title)
    |> Repo.one()
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
  end

  def update_ingest_sheet_status({:ok, %Sheet{} = ingest_sheet}, status) do
    update_ingest_sheet_status(ingest_sheet, status)
  end

  @doc """
  Gets the list of states for a single sheet.

  ## Examples

      iex> get_sheet_validation_state(123)
      [
        %{ title: "overall", value: "pending" }
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

  def list_ingest_sheet_row_success_fail(id) do
    Row
    |> select([row], [row.state, count(row)])
    |> where([row], row.sheet_id == ^id)
    |> group_by([row], [row.state])
    |> order_by([row], asc: row.state)
    |> Meadow.Repo.all()
    |> Enum.map(fn [state, count] ->
      case state do
        "pass" ->
          %{pass: count}

        "fail" ->
          %{fail: count}

        _ ->
          :noop
      end
    end)
    |> Enum.reduce(fn x, acc ->
      Map.merge(x, acc, fn _key, map1, map2 ->
        for {k, v1} <- map1, into: %{}, do: {k, v1 + map2[k]}
      end)
    end)
    |> set_default_pass_fail()
  end

  defp set_default_pass_fail(%{pass: _pass, fail: _fail} = stats), do: stats

  defp set_default_pass_fail(%{pass: pass}) do
    %{pass: pass, fail: 0}
  end

  defp set_default_pass_fail(%{fail: fail}) do
    %{pass: 0, fail: fail}
  end

  defp set_default_pass_fail(_) do
    %{pass: 0, fail: 0}
  end

  def list_ingest_sheet_works(ingest_sheet, limit \\ nil)

  def list_ingest_sheet_works(%Sheet{} = ingest_sheet, limit) do
    ingest_sheet.id
    |> list_ingest_sheet_works(limit)
  end

  def list_ingest_sheet_works(sheet_id, limit) do
    from(w in Work,
      where: w.ingest_sheet_id == ^sheet_id,
      limit: ^limit
    )
    |> Repo.all()
    |> Works.add_representative_image()
  end

  def work_count(%{} = ingest_sheet), do: work_count(ingest_sheet.id)

  def work_count(sheet_id) do
    from(w in Work,
      where: w.ingest_sheet_id == ^sheet_id,
      select: count(w.ingest_sheet_id)
    )
    |> Repo.one()
  end

  def file_set_count(%Sheet{} = ingest_sheet), do: file_set_count(ingest_sheet.id)

  def file_set_count(sheet_id) do
    from(r in Row,
      where: r.sheet_id == ^sheet_id,
      select: count(r.sheet_id)
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

  def sheet_has_errors_query(sheet_id) do
    row_errors =
      from([entry: entry, row: row] in row_action_states(sheet_id),
        where: entry.outcome in ["error", "skipped"],
        select: entry.object_id
      )

    file_set_errors =
      from([entry: entry, row: row] in file_set_action_states(sheet_id),
        where: entry.outcome in ["error", "skipped"],
        select: entry.object_id
      )

    from(row_errors, distinct: true, union_all: ^file_set_errors)
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
      join: r in Row,
      as: :row,
      on: r.file_set_accession_number == f.accession_number,
      where: w.ingest_sheet_id == ^sheet_id
    )
  end

  @doc "Composable query to add sheet_title and project_title to works"
  def works_with_sheets(query \\ Work) do
    from w in query,
      left_join: s in Sheet,
      on: s.id == w.ingest_sheet_id,
      left_join: p in Project,
      on: s.project_id == p.id,
      select_merge: %{
        extra_index_fields: %{
          sheet: %{id: s.id, title: s.title},
          project: %{id: p.id, title: p.title}
        }
      }
  end

  def find_state(ingest_sheet, key \\ "overall"), do: Sheet.find_state(ingest_sheet, key)

  def list_ingest_sheets_by_status(status) do
    with status_string <- to_string(status) do
      from(s in Sheet, where: s.status == ^status_string)
      |> Repo.all()
    end
  end

  def list_recently_updated(seconds) do
    since = DateTime.utc_now() |> DateTime.add(-seconds, :second)

    from(s in Sheet,
      where: s.updated_at >= ^since
    )
    |> Repo.all()
  end

  def update_completed_sheets() do
    from(s in Sheet, where: s.status == "approved")
    |> Repo.all()
    |> Enum.each(&check_sheet_for_completeness/1)
  end

  def check_sheet_for_completeness(%Sheet{} = sheet) do
    sheet_statuses =
      from(r in Row,
        join: p in Progress,
        on: r.id == p.row_id,
        select: [p.status],
        where: r.sheet_id == ^sheet.id,
        distinct: true
      )
      |> Repo.all()
      |> List.flatten()
      |> Enum.sort()

    case sheet_statuses do
      ["ok"] -> update_ingest_sheet_status(sheet, "completed")
      ["error" | _] -> update_ingest_sheet_status(sheet, "completed_error")
      _ -> {:ok, sheet}
    end
  end
end
