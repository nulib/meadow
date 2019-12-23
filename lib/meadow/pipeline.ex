defmodule Meadow.Pipeline do
  @moduledoc """
  Defines the supervision tree for the ingest pipeline
  """
  use Sequins.Pipeline

  alias Meadow.Data.ActionStates
  alias Meadow.Data.Schemas.FileSet

  def kickoff(_, context \\ %{})

  def kickoff(%FileSet{} = file_set, context), do: kickoff(file_set.id, context)

  def kickoff(file_set_id, context) do
    ActionStates.initialize_states({FileSet, file_set_id}, actions())

    with initial_action <- List.first(actions()) do
      initial_action.send_message(%{file_set_id: file_set_id}, context)
    end
  end
end
