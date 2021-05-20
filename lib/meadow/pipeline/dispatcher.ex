defmodule Meadow.Pipeline.Actions.Dispatcher do
  @moduledoc """
  Action responsible for dispatching processing to
  the next action in the pipeline

  Subscribes to: all other actions with status: :ok
  *

  """
  alias Meadow.Data.{ActionStates, FileSets}
  alias Meadow.Utils.Atoms
  alias Sequins.Pipeline.Action

  alias Meadow.Pipeline.Actions.{
    CopyFileToPreservation,
    CreatePyramidTiff,
    ExtractMimeType,
    FileSetComplete,
    GenerateFileSetDigests,
    ExtractExifMetadata,
    IngestFileSet,
    InitializeDispatch
  }

  use Action
  require Logger

  @actiondoc "Disatch pipeline actions specific to role + mime_type"

  @initial_actions [
    IngestFileSet,
    ExtractMimeType,
    InitializeDispatch
  ]

  @access_image_actions [
    GenerateFileSetDigests,
    ExtractExifMetadata,
    CopyFileToPreservation,
    CreatePyramidTiff,
    FileSetComplete
  ]

  @preservation_actions [
    GenerateFileSetDigests,
    CopyFileToPreservation,
    FileSetComplete
  ]

  @preservation_image_actions [
    GenerateFileSetDigests,
    ExtractExifMetadata,
    CopyFileToPreservation,
    FileSetComplete
  ]

  def process(data, attributes) do
    Logger.info("dispatcher called")
    file_set = FileSets.get_file_set(data.file_set_id)

    dispatch_next_action(file_set, attributes)
    :ok
  end

  def process(data, attributes, _), do: process(data, attributes)

  def initial_actions, do: @initial_actions

  def all_progress_actions do
    Enum.uniq(
      @initial_actions ++
        @preservation_actions ++ @preservation_image_actions ++ @access_image_actions
    )
  end

  def dispatcher_actions(%{role: %{id: "A"}, core_metadata: %{mime_type: "image/" <> _}}),
    do: @access_image_actions

  def dispatcher_actions(%{role: %{id: "X"}, core_metadata: %{mime_type: "image/" <> _}}),
    do: @access_image_actions

  def dispatcher_actions(%{role: %{id: "P"}, core_metadata: %{mime_type: "image/" <> _}}),
    do: @preservation_image_actions

  def dispatcher_actions(%{role: %{id: "S"}}),
    do: @preservation_actions

  def dispatcher_actions(_), do: nil

  def not_my_actions(file_set) do
    (all_progress_actions() -- @initial_actions) -- dispatcher_actions(file_set)
  end

  defp dispatch_next_action(file_set, attributes) do
    last = ActionStates.get_latest_state(file_set.id)

    next_action =
      next_action(
        last.action,
        dispatcher_actions(file_set)
      )

    Logger.info(
      "Last action was: #{last.action}, next action is: #{next_action} for file set id: #{
        file_set.id
      }"
    )

    next_action.send_message(%{file_set_id: file_set.id}, attributes)
  end

  defp next_action(last_action, action_queue) do
    index = action_queue |> Enum.find_index(&(Atoms.atom_to_string(&1) == last_action))

    case index do
      nil ->
        Enum.at(action_queue, 0)

      number ->
        Enum.at(action_queue, number + 1)
    end
  end
end
