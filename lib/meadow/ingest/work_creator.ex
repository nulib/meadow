defmodule Meadow.Ingest.WorkCreator do
  @moduledoc """
  GenServer to create works from pending ingest sheet rows
  """
  use GenServer

  import Ecto.Query, warn: false
  alias Meadow.Config
  alias Meadow.Data.{ActionStates, Works}
  alias Meadow.Data.Schemas.{FileSet, Work}
  alias Meadow.Ingest.{Progress, Rows}
  alias Meadow.Ingest.Schemas.Row
  alias Meadow.Pipeline
  alias Meadow.Repo

  use Meadow.Constants

  require Logger

  @timeout 60

  def child_spec(opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [opts]}
    }
  end

  def start_link(args \\ []) do
    GenServer.start_link(__MODULE__, args)
  end

  def init(args) do
    Logger.info("Starting #{__MODULE__}")

    state = %{
      create_interval: Keyword.get(args, :create_interval, 500),
      redrive_interval: Keyword.get(args, :redrive_interval, :timer.seconds(60)),
      batch_size: Keyword.get(args, :batch_size, 20)
    }

    Process.send_after(self(), :create_works, state.create_interval)
    Process.send_after(self(), :redrive_works, state.redrive_interval)

    {:ok, state}
  end

  @doc """
  Find works that have been processing longer than @timeout and
  reset them to pending
  """
  def handle_info(:redrive_works, state) do
    Logger.disable(self())

    {count, _} =
      Progress.works_processing_longer_than(@timeout)
      |> Repo.update_all(set: [status: "pending", updated_at: DateTime.utc_now()])

    Logger.enable(self())

    if count > 0,
      do: Logger.info("Redriving #{count} works processing longer than #{@timeout} seconds")

    Process.send_after(self(), :redrive_works, state.redrive_interval)
    {:noreply, state}
  end

  @doc """
  Turn a batch of pending work rows into works
  """
  def handle_info(:create_works, state) do
    Logger.disable(self())

    case Progress.get_pending_work_entries(state.batch_size)
         |> Progress.update_entries("CreateWork", "processing")
         |> Repo.preload(row: :sheet) do
      [] ->
        :noop

      work_rows ->
        Logger.enable(self())
        Logger.info("Creating #{length(work_rows)} works")
        create_works(work_rows)
    end

    Process.send_after(self(), :create_works, state.create_interval)
    {:noreply, state}
  after
    Logger.enable(self())
  end

  def handle_info({:ssl_closed, _msg}, state), do: {:noreply, state}

  @doc """
  Create works from pending `CreateWork` progress rows
  """
  def create_works(work_rows) do
    work_rows
    |> Enum.map(fn pending_work_row ->
      sheet = pending_work_row.row.sheet
      work_accession_number = pending_work_row.row |> Row.field_value("work_accession_number")
      file_set_rows = Rows.get_rows_by_work_accession_number(sheet.id, work_accession_number)
      ingest_work({work_accession_number, file_set_rows}, sheet)
    end)
  end

  @doc """
  Send a single work to the ingest pipeline with the proper
  ingest sheet metadata
  """
  def send_work_to_pipeline(ingest_sheet, work, file_set_rows) do
    work.file_sets
    |> Enum.zip(file_set_rows)
    |> Enum.each(fn {%FileSet{id: file_set_id}, %Row{row: row_num}} ->
      Pipeline.kickoff(file_set_id, %{
        context: "Sheet",
        ingest_sheet: ingest_sheet.id,
        ingest_sheet_row: row_num
      })
    end)

    work
  end

  @doc """
  Ingest a single work and update its status inside a single atomic transaction
  """
  def ingest_work({accession_number, file_set_rows}, ingest_sheet) do
    Logger.info("Creating work #{accession_number} with #{length(file_set_rows)} file sets")

    ingest_bucket = Config.ingest_bucket()

    attrs = %{
      accession_number: accession_number,
      file_sets:
        file_set_rows
        |> Enum.map(fn row ->
          file_path = Row.field_value(row, :filename)
          location = "s3://#{ingest_bucket}/#{file_path}"

          %{
            accession_number: row |> Row.field_value(:accession_number),
            role: row |> Row.field_value(:role),
            metadata: %{
              description: row |> Row.field_value(:description),
              location: location,
              original_filename: Path.basename(file_path),
              label: Path.basename(file_path)
            }
          }
        end),
      ingest_sheet_id: ingest_sheet.id,
      published: false,
      visibility: %{id: "RESTRICTED", scheme: "visibility"},
      work_type: %{id: "IMAGE", scheme: "work_type"}
    }

    on_complete = fn work ->
      Progress.update_entry(List.first(file_set_rows), "CreateWork", "ok")
      ActionStates.set_state!(work, "Create Work", "ok")
      send_work_to_pipeline(ingest_sheet, work, file_set_rows)
    end

    case Works.ensure_create_work(attrs, on_complete) do
      {:ok, %Work{} = work} ->
        work

      {:error, changeset} ->
        create_changeset_errors(changeset, file_set_rows)
    end
  end

  defp create_changeset_errors(changeset, file_set_rows) do
    with row <- file_set_rows |> List.first() do
      create_errors(
        row,
        "Create Work",
        errors_to_strings(changeset.errors)
      )
    end

    file_set_rows
    |> Enum.with_index()
    |> Enum.each(fn {row, index} ->
      with fs_changeset <- Enum.at(changeset.changes.file_sets, index) do
        create_errors(
          row,
          "CreateFileSet",
          errors_to_strings(fs_changeset.errors)
        )
      end
    end)

    nil
  end

  defp create_errors(ingest_sheet_row, action, []) do
    ActionStates.set_state!(ingest_sheet_row, action, "skipped")
  end

  defp create_errors(ingest_sheet_row, action, errors) do
    ActionStates.set_state!(ingest_sheet_row, action, "error", Enum.join(errors, "; "))
  end

  defp errors_to_strings(errors) do
    errors
    |> Enum.map(fn {field, {message, _opts}} ->
      [to_string(field), message] |> Enum.join(": ")
    end)
  end
end
