defmodule Meadow.Data.PipelineTest do
  @moduledoc """
  Tests for Pipeline API
  """
  use Meadow.DataCase
  use ExUnit.Case

  alias Meadow.Data.ActionStates
  alias Meadow.Data.Schemas.{ActionState, FileSet}
  alias Meadow.Pipeline
  alias Meadow.Pipeline.Actions.Dispatcher

  import Assertions

  describe "ingesting file set" do
    @valid_attrs %{
      accession_number: "12345",
      role: %{id: "A", scheme: "FILE_SET_ROLE"},
      core_metadata: %{
        description: "yes",
        location: "https://example.com",
        original_filename: "test.tiff"
      }
    }

    test "ingest_file_set/1 creates a file_set" do
      assert {:ok, %FileSet{} = _file_set} = Pipeline.ingest_file_set(@valid_attrs)
    end

    test "ingest_file_set/1 kicks off the ingest pipeline for a file set" do
      {:ok, file_set} = Pipeline.ingest_file_set(@valid_attrs)
      assert [%ActionState{} | _states] = ActionStates.get_states(file_set.id)
    end

    test "kickoff pipeline creates action_state records for initial common actions" do
      preservation_attrs = %{
        accession_number: "12345",
        role: %{id: "A", scheme: "FILE_SET_ROLE"},
        metadata: %{
          description: "yes",
          location: "https://example.com",
          original_filename: "test.tiff"
        }
      }

      {:ok, file_set} = Pipeline.ingest_file_set(preservation_attrs)

      assert ActionStates.get_states(file_set.id) |> length() ==
               Dispatcher.initial_actions() |> length()

      assert_lists_equal(
        ActionStates.get_states(file_set.id) |> Enum.map(fn state -> state.action end),
        [
          "Meadow.Pipeline.Actions.ExtractMimeType",
          "Meadow.Pipeline.Actions.IngestFileSet",
          "Meadow.Pipeline.Actions.InitializeDispatch"
        ]
      )

      ActionStates.get_states(file_set.id)
      |> Enum.each(fn action -> assert action.outcome == "waiting" end)
    end
  end
end
