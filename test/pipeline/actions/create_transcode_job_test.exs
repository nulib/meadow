defmodule Meadow.Pipeline.Actions.CreateTranscodeJobTest do
  use Meadow.DataCase
  alias Meadow.Data.ActionStates
  alias Meadow.Pipeline.Actions.CreateTranscodeJob
  import ExUnit.CaptureLog

  describe "file set exists" do
    test "process/2" do
      object =
        file_set_fixture(
          role: %{id: "A", scheme: "FILE_SET_ROLE"},
          core_metadata: %{
            mime_type: "video/mov",
            location: "s3://test-ingest/test.mov",
            original_filename: "test.mov"
          }
        )

      assert(CreateTranscodeJob.process(%{file_set_id: object.id}, %{}) == :ok)
      assert(ActionStates.ok?(object.id, CreateTranscodeJob))

      assert capture_log(fn ->
               CreateTranscodeJob.process(%{file_set_id: object.id}, %{})
             end) =~ "Skipping #{CreateTranscodeJob} for #{object.id} – already complete"
    end
  end

  describe "file set does not exist" do
    test "process/2" do
      nonexistent_file_set_id = Ecto.UUID.generate()

      assert capture_log(fn ->
               assert(
                 {:error, _reason} =
                   CreateTranscodeJob.process(%{file_set_id: nonexistent_file_set_id}, %{})
               )
             end) =~
               "Marking #{CreateTranscodeJob} for #{nonexistent_file_set_id} as error because the file set was not found"
    end
  end

  describe "handle errors from MediaConvert response" do
    test "process/2" do
      mock_error_file_input = "s3://input-error/test.mov"

      object =
        file_set_fixture(
          role: %{id: "A", scheme: "FILE_SET_ROLE"},
          core_metadata: %{
            mime_type: "video/mov",
            location: mock_error_file_input,
            original_filename: "test.mov"
          }
        )

      assert capture_log(fn ->
               assert(
                 {:error, "Fake error response"} =
                   CreateTranscodeJob.process(%{file_set_id: object.id}, %{})
               )
             end) =~
               "Error creating MediaConvert Job"
    end
  end
end
