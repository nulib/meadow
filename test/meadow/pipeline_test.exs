defmodule Meadow.Data.PipelineTest do
  @moduledoc """
  Tests for Pipeline API
  """
  use Meadow.DataCase
  use ExUnit.Case

  alias Meadow.Data.ActionStates
  alias Meadow.Data.Schemas.{ActionState, FileSet}
  alias Meadow.Pipeline

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

    test "kickoff access (Image) file pipeline initializes CreatePyramidTiff action" do
      {:ok, file_set} = Pipeline.ingest_file_set(@valid_attrs)

      assert %{outcome: "waiting"} =
               ActionStates.get_latest_state(
                 file_set.id,
                 Meadow.Pipeline.Actions.CreatePyramidTiff
               )
    end

    test "kickoff preservation (Image) file pipeline does not initialize CreatePyramidTiff action" do
      preservation_attrs = %{
        accession_number: "12345",
        role: %{id: "P", scheme: "FILE_SET_ROLE"},
        core_metadata: %{
          description: "yes",
          location: "https://example.com",
          original_filename: "test.tiff"
        }
      }

      {:ok, file_set} = Pipeline.ingest_file_set(preservation_attrs)

      assert nil ==
               ActionStates.get_latest_state(
                 file_set.id,
                 Meadow.Pipeline.Actions.CreatePyramidTiff
               )
    end
  end
end
