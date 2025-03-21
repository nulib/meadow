defmodule Meadow.Pipeline.Actions.CreateTranscodeJobTest do
  use Meadow.S3Case
  use Meadow.DataCase
  use Meadow.PipelineCase

  alias Meadow.Data.ActionStates
  alias Meadow.Pipeline.Actions.CreateTranscodeJob

  import ExUnit.CaptureLog

  describe "file set exists" do
    setup do
      upload_object(@ingest_bucket, "small.m4v", File.read!("test/fixtures/small.m4v"))

      on_exit(fn ->
        delete_object(@ingest_bucket, "small.m4v")
        empty_bucket(@streaming_bucket)
      end)

      :ok
    end

    test "process/2" do
      %{id: file_set_id} =
        file_set_fixture(
          role: %{id: "A", scheme: "FILE_SET_ROLE"},
          core_metadata: %{
            mime_type: "video/mov",
            location: "s3://#{@ingest_bucket}/small.m4v",
            original_filename: "small.m4v"
          }
        )

      assert {:ok, %{id: ^file_set_id}, %{}} =
               send_test_message(CreateTranscodeJob, %{file_set_id: file_set_id}, %{})

      assert(ActionStates.ok?(file_set_id, CreateTranscodeJob))

      assert capture_log(fn ->
               send_test_message(CreateTranscodeJob, %{file_set_id: file_set_id}, %{})
             end) =~ "Skipping #{CreateTranscodeJob} for #{file_set_id} - already complete"
    end
  end

  describe "file set does not exist" do
    test "process/2" do
      nonexistent_file_set_id = Ecto.UUID.generate()

      assert capture_log(fn ->
               assert {:error, _reason} =
                        send_test_message(
                          CreateTranscodeJob,
                          %{file_set_id: nonexistent_file_set_id},
                          %{}
                        )
             end) =~
               "Marking #{CreateTranscodeJob} for #{nonexistent_file_set_id} as error because the file set was not found"
    end
  end

  describe "handle errors from MediaConvert response" do
    test "process/2" do
      mock_error_file_input = "s3://input-error/small.m4v"

      %{id: file_set_id} =
        file_set_fixture(
          role: %{id: "A", scheme: "FILE_SET_ROLE"},
          core_metadata: %{
            mime_type: "video/mov",
            location: mock_error_file_input,
            original_filename: "small.m4v"
          }
        )

      assert capture_log(fn ->
               assert {:error, _, %{error: "Fake error response"}} =
                        send_test_message(CreateTranscodeJob, %{file_set_id: file_set_id}, %{})
             end) =~
               "Error creating MediaConvert Job"
    end
  end
end
