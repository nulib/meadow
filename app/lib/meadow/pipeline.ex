defmodule Meadow.Pipeline do
  @moduledoc """
  Defines the supervision tree for the ingest pipeline
  """
  use Meadow.Utils.Logging

  alias Meadow.Config
  alias Meadow.Data.{ActionStates, FileSets}
  alias Meadow.Data.Schemas.FileSet
  alias Meadow.Pipeline.Dispatcher
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
