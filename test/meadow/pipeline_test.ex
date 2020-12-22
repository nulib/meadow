defmodule Meadow.Data.PipelineTest do
  @moduledoc """
  Tests for Pipeline API
  """
  use Meadow.DataCase
  use ExUnit.Case

  alias Meadow.Data.{ActionStates, FileSets}
  alias Meadow.Data.Schemas.{ActionState, FileSet}

  describe "ingesting file set" do
    @valid_attrs %{
      accession_number: "12345",
      role: "am",
      metadata: %{
        description: "yes",
        location: "https://example.com",
        original_filename: "test.tiff"
      }
    }

    test "ingest_file_set/1 creates a file_set" do
      assert {:ok, %FileSet{} = _file_set} = FileSets.ingest_file_set(@valid_attrs)
    end

    test "ingest_file_set/1 kicks off the ingest pipeline for a file set" do
      {:ok, file_set} = FileSets.ingest_file_set(@valid_attrs)
      assert [%ActionState{} | states] = ActionStates.get_states(file_set.id)
    end
  end
end
