defmodule Meadow.Ingest.Progress do
  @moduledoc """
  Translate action state notifications into ingest sheet progress notifications
  """
  use Meadow.Utils.Logging

  alias Meadow.Ingest.Schemas.{Progress, Row, Sheet}
  alias Meadow.Ingest.{Rows, Sheets}
  alias Meadow.IntervalTask
  alias Meadow.Pipeline.Dispatcher
  alias Meadow.Repo

  import Ecto.Query
  import Meadow.Utils.Atoms

  use IntervalTask, default_interval: 500, function: :send_notifications_and_update_sheet_status
  require Logger

  defstruct sheet_id: nil,
            total_file_sets: 0,
            completed_file_sets: 0,
            total_actions: 0,
            completed_actions: 0,
            percent_complete: 0

  @doc """
  Retrieve all progress entries for an ingest sheet
  """
  def get_entries(sheet) do
    progress_entries(sheet)
    |> Repo.all()
  end

  @doc """
  Errors out all remaining pending entries for a row
  """
  def abort_remaining_pending_entries(%{ingest_sheet: ingest_sheet_id, ingest_sheet_row: row_id}) do
    from(p in Progress,
      as: :entry,
      join: r in Row,
      as: :row,
      on: r.id == p.row_id,
      where: r.row == ^row_id and p.status == "pending" and r.sheet_id == ^ingest_sheet_id
    )
    |> Repo.update_all(set: [status: "error"])
  end

  # UI upload or case w/out ingest sheet
  def abort_remaining_pending_entries(_), do: :noop

  @doc """
  Retrieve a progress entry by ingest sheet row ID and action name
  """
  def get_entry(%Row{} = row, action), do: get_entry(row.id, action)

  def get_entry(row_id, action) do
    action = atom_to_string(action)

    from(p in Progress, where: p.row_id == ^row_id and p.action == ^action)
    |> Repo.one()
  end

  def get_and_lock_pending_work_entries(sheet_id, limit) do
    from(q in pending_work_entry_query(limit),
      join: r in Row,
      on: q.row_id == r.id,
      where: r.sheet_id == ^sheet_id,
      lock: "FOR UPDATE SKIP LOCKED"
    )
    |> Repo.all()
  end

  def get_and_lock_pending_work_entries(limit) do
    from(q in pending_work_entry_query(limit), lock: "FOR UPDATE SKIP LOCKED")
    |> Repo.all()
  end

  defp pending_work_entry_query(limit) do
    with q <- from(p in Progress, where: p.action == "CreateWork" and p.status == "pending") do
      if limit == :all, do: q, else: limit(q, ^limit)
    end
  end

  def works_processing_longer_than(seconds) do
    timeout = DateTime.utc_now() |> DateTime.add(-seconds, :second)

    from(p in Progress,
      where:
        p.action == "CreateWork" and
          p.status == "processing" and
          p.updated_at <= ^timeout
    )
  end

  @doc """
  Initialize progress entries for a given ingest sheet row, including
  an additional entry if the row creates a new work
  """
  def initialize_entry(%Row{} = row, include_work) do
    initialize_entry(row.id, include_work)
  end

  def initialize_entry(row_id, include_work) do
    row_actions(include_work)
    |> Enum.each(fn action -> update_entry(row_id, action, "pending") end)
  end

  def initialize_entries(entries) do
    timestamp = DateTime.utc_now()

    Repo.transaction(
      fn ->
        entries
        |> Enum.chunk_every(500)
        |> Enum.each(&initialize_chunk(&1, timestamp))
      end,
      timeout: :infinity
    )
  end

  defp initialize_chunk(chunk, timestamp) do
    new_entries =
      Enum.flat_map(chunk, fn {row_id, include_work} ->
        row_actions(include_work)
        |> Enum.map(fn action ->
          %{
            row_id: row_id,
            action: atom_to_string(action),
            status: "pending",
            inserted_at: timestamp,
            updated_at: timestamp
          }
        end)
      end)

    Repo.insert_all(Progress, new_entries)
  end

  @doc """
  Update the status of several progress entries at once
  """
  def update_entries(entries, action, status) when is_list(entries) do
    now = DateTime.utc_now()
    row_ids = Enum.map(entries, fn %{row_id: id} -> id end)

    {_count, result} =
      from(p in Progress,
        where: p.row_id in ^row_ids and p.action == ^action,
        select: p
      )
      |> Repo.update_all(set: [status: status, updated_at: now])

    result
  end

  def update_entries(%Row{} = entry, actions, status) when is_list(actions) do
    update_entries(entry.id, actions, status)
  end

  def update_entries(entry_id, actions, status) when is_list(actions) do
    now = DateTime.utc_now()
    actions = Enum.map(actions, fn a -> atom_to_string(a) end)

    {_count, result} =
      from(p in Progress,
        where: p.row_id == ^entry_id and p.action in ^actions,
        select: p
      )
      |> Repo.update_all(set: [status: status, updated_at: now])

    result
  end

  @doc """
  Update the status of a progress entry for a given ingest sheet row and action
  """
  def update_entry(%Row{} = row, action, status) do
    progress =
      case get_entry(row.id, action) do
        nil -> %Progress{row_id: row.id, action: atom_to_string(action)}
        row -> row
      end
      |> Progress.changeset(%{status: status})
      |> Repo.insert_or_update!()

    progress
  end

  def update_entry(row_id, action, status),
    do: update_entry(Rows.get_row(row_id), action, status)

  @doc """
  Get the total number of actions for an ingest sheet
  """
  def action_count(sheet) do
    sheet
    |> progress_entries()
    |> Repo.aggregate(:count)
  end

  @doc """
  Get the number of completed actions for an ingest sheet
  """
  def completed_count(sheet) do
    from([entry: p] in progress_entries(sheet), where: p.status in ["ok", "error"])
    |> Repo.aggregate(:count)
  end

  @doc """
  Get the total number of file sets for an ingest sheet
  """
  def file_set_count(sheet) do
    from([entry: p] in progress_entries(sheet),
      where: p.action == "Meadow.Pipeline.Actions.FileSetComplete"
    )
    |> Repo.aggregate(:count)
  end

  @doc """
  Get the number of completed file sets for an ingest sheet
  """
  def completed_file_set_count(sheet) do
    from([entry: p] in progress_entries(sheet),
      where:
        p.action == "Meadow.Pipeline.Actions.FileSetComplete" and
          p.status in ["ok", "error"]
    )
    |> Repo.aggregate(:count)
  end

  defp row_actions(include_work) do
    if include_work do
      ["CreateWork" | Dispatcher.all_progress_actions()]
    else
      Dispatcher.all_progress_actions()
    end
  end

  defp progress_entries(%Sheet{} = sheet), do: progress_entries(sheet.id)

  defp progress_entries(sheet_id) do
    from p in Progress,
      as: :entry,
      join: r in Row,
      as: :row,
      on: r.id == p.row_id,
      where: r.sheet_id == ^sheet_id
  end

  @doc """
  Get the total progress report for an ingest sheet
  """
  def pipeline_progress(%Sheet{} = sheet), do: pipeline_progress(sheet.id)

  def pipeline_progress(sheet_id) do
    case action_count(sheet_id) do
      0 ->
        %__MODULE__{sheet_id: sheet_id}

      action_count ->
        completed_action_count = completed_count(sheet_id)
        percent_complete = round(completed_action_count / action_count * 10_000) / 100

        %__MODULE__{
          sheet_id: sheet_id,
          total_file_sets: file_set_count(sheet_id),
          completed_file_sets: completed_file_set_count(sheet_id),
          total_actions: action_count,
          completed_actions: completed_action_count,
          percent_complete: percent_complete
        }
    end
  end

  def send_notifications do
    Sheets.list_ingest_sheets_by_status(:approved)
    |> Enum.each(&send_notification(&1.id))

    Sheets.list_recently_updated(60)
    |> Enum.each(&send_notification(&1.id))
  end

  def send_notification(sheet_id) do
    Meadow.Notification.publish(
      pipeline_progress(sheet_id),
      ingest_progress: sheet_id
    )
  end

  def send_notifications_and_update_sheet_status(state) do
    with_log_level :info do
      send_notifications()
    end

    Sheets.update_completed_sheets()

    {:noreply, state}
  end
end
