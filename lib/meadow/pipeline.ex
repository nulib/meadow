defmodule Meadow.Pipeline do
  @moduledoc """
  Defines the supervision tree for the ingest pipeline
  """
  use Sequins.Pipeline

  alias Meadow.Data.{ActionStates, FileSets}
  alias Meadow.Data.Schemas.FileSet
  alias Meadow.Pipeline.Actions.Dispatcher

  def ingest_file_set(attrs \\ %{}) do
    case FileSets.create_file_set(attrs) do
      {:ok, file_set} ->
        kickoff(file_set, %{role: file_set.role.id})
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
end
