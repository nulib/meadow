defmodule Meadow.Pipeline do
  @moduledoc """
  Defines the supervision tree for the ingest pipeline
  """
  use Sequins.Pipeline

  alias Meadow.Config
  alias Meadow.Data.{ActionStates, FileSets}
  alias Meadow.Data.Schemas.FileSet
  alias Meadow.Pipeline.Actions.Dispatcher
  alias Meadow.Utils.AWS

  require Logger

  import WaitForIt

  def ingest_file_set(attrs \\ %{}) do
    case FileSets.create_file_set(attrs) do
      {:ok, file_set} ->
        Task.async(fn -> wait_for_checksum_tags(file_set) end)
        {:ok, file_set}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  def kickoff(_, context \\ %{})

  def kickoff(%FileSet{} = file_set, context), do: kickoff(file_set.id, context)

  def kickoff(file_set_id, context) do
    actions = Dispatcher.initial_actions()
    ActionStates.initialize_states({FileSet, file_set_id}, actions)

    with initial_action <- List.first(actions) do
      initial_action.send_message(%{file_set_id: file_set_id}, context)
    end
  end

  defp wait_for_checksum_tags(%{core_metadata: %{location: location}} = file_set) do
    with %{host: bucket, path: "/" <> key} <- URI.parse(location) do
      case wait(AWS.check_object_tags!(bucket, key, Config.required_checksum_tags()),
             timeout: Config.checksum_wait_timeout(),
             frequency: 1_000
           ) do
        {:ok, true} ->
          kickoff(file_set, %{role: file_set.role.id})

        {:timeout, timeout} ->
          Logger.error(
            "Timed out after #{timeout}ms waiting for checksum tags for file set id: #{file_set.id}"
          )
      end
    end
  end
end
