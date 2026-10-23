defmodule Meadow.Pipeline do
  @moduledoc """
  Defines the supervision tree for the ingest pipeline
  """
  use Meadow.Utils.Logging

  alias Meadow.Config
  alias Meadow.Data.{ActionStates, FileSets}
  alias Meadow.Data.Schemas.FileSet
  alias Meadow.Ingest.Progress
  alias Meadow.Pipeline.Dispatcher
  alias Meadow.Repo
  alias Meadow.Utils.AWS

  require Logger

  import WaitForIt

  def actions do
    Application.get_env(:meadow, Meadow.Pipeline)
    |> Keyword.get(:actions)
  end

  def children do
    actions()
    |> Enum.map(fn action ->
      {action, Application.get_env(:meadow, __MODULE__, []) |> Keyword.get(action, [])}
    end)
  end

  def ingest_file_set(attrs \\ %{}) do
    case FileSets.create_file_set(attrs) do
      {:ok, file_set} ->
        Task.async(fn -> wait_for_checksum_tags(file_set) end)
        {:ok, file_set}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  def replace_the_file_set(file_set, attrs \\ %{}) do
    case FileSets.replace_file_set(file_set, attrs) do
      {:ok, file_set} ->
        Task.async(fn -> wait_for_checksum_tags(file_set, %{context: "Version"}) end)
        {:ok, file_set}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  def kickoff(_, context \\ %{})

  def kickoff(%FileSet{} = file_set, context), do: kickoff(file_set.id, context)

  def kickoff(file_set_id, context) do
    with_log_metadata module: __MODULE__, id: file_set_id do
      Logger.info("Initializing action states for file set #{file_set_id}")
      actions = Dispatcher.initial_actions()
      ActionStates.initialize_states({FileSet, file_set_id}, actions)

      with initial_action <- List.first(actions) do
        Logger.info("Dispatching file set #{file_set_id} to #{initial_action}")
        initial_action.send_message(%{file_set_id: file_set_id}, context)
      end
    end
  end

  @doc """
  Retry a failed ingest pipeline run for a file set.

  Discovers whether the file set was created as part of an ingest sheet, clears
  any failed action states (leaving the successful ones alone), and re-dispatches
  the pipeline starting at the first action that hasn't succeeded. When the file
  set came from an ingest sheet, the sheet and row are passed along in the
  message context so the sheet's progress is updated as the retried actions run.

  Returns `{:ok, action}` with the action the pipeline was restarted from,
  `{:error, :not_found}` if the file set doesn't exist, or `{:error, :no_failures}`
  if there's nothing to retry.
  """
  def retry(%FileSet{} = file_set), do: retry(file_set.id)

  def retry(file_set_id) do
    case FileSets.get_file_set(file_set_id) do
      nil -> {:error, :not_found}
      file_set -> do_retry(file_set)
    end
  end

  defp do_retry(file_set) do
    with_log_metadata module: __MODULE__, id: file_set.id do
      row = Repo.preload(file_set, :ingest_sheet_row) |> Map.get(:ingest_sheet_row)
      context = retry_context(file_set, row)

      with true <- ActionStates.error?(file_set.id),
           action when not is_nil(action) <- first_incomplete_action(file_set, context) do
        ActionStates.reset_failed_states(file_set.id)
        if row, do: Progress.reset_failed_entries(row)

        Logger.info("Retrying file set #{file_set.id} from #{action}")
        action.send_message(%{file_set_id: file_set.id}, context)
        {:ok, action}
      else
        _ ->
          Logger.info("No failed actions to retry for file set #{file_set.id}")
          {:error, :no_failures}
      end
    end
  end

  defp retry_context(file_set, nil), do: %{role: file_set.role.id}

  defp retry_context(file_set, row) do
    %{
      context: "Sheet",
      role: file_set.role.id,
      ingest_sheet: row.sheet_id,
      ingest_sheet_row: row.row
    }
  end

  # The first action in the file set's pipeline that hasn't succeeded. Actions
  # aborted by an earlier failure are "error" too, so this finds the action that
  # actually failed rather than the last one marked.
  defp first_incomplete_action(file_set, context) do
    with dispatched <- Dispatcher.dispatcher_actions(file_set, context) || [] do
      (Dispatcher.initial_actions() ++ dispatched)
      |> Enum.find(&(not ActionStates.ok?(file_set.id, &1)))
    end
  end

  defp wait_for_checksum_tags(%{core_metadata: %{location: location}} = file_set, context \\ %{}) do
    with %{host: bucket, path: "/" <> key} <- URI.parse(location),
         timeout <- Config.checksum_wait_timeout() do
      if wait(AWS.check_object_tags!(bucket, key, Config.required_checksum_tags()),
           timeout: timeout,
           frequency: 1_000
         ) do
        kickoff(file_set, Map.merge(context, %{role: file_set.role.id}))
      else
        Logger.error(
          "Timed out after #{timeout}ms waiting for checksum tags for file set id: #{file_set.id}"
        )
      end
    end
  end
end
