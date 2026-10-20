defmodule Meadow.Pipeline.Actions.CreateTranscodeJobTest do
  use Meadow.S3Case
  use Meadow.DataCase
  use Meadow.PipelineCase

  alias Meadow.Data.ActionStates
  alias Meadow.Pipeline.Actions.CreateTranscodeJob
  alias Meadow.Metrics.Aggregator

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

    test "telemetry" do
      Aggregator.reset()
      on_exit(&Aggregator.reset/0)

      %{id: file_set_id} =
        file_set_fixture(
          role: %{id: "A", scheme: "FILE_SET_ROLE"},
          core_metadata: %{
            mime_type: "video/mov",
            location: "s3://#{@ingest_bucket}/small.m4v",
            original_filename: "small.m4v"
          }
        )

      send_test_message(CreateTranscodeJob, %{file_set_id: file_set_id}, %{})

      # Assert the dimension VALUE, not just that the metric exists. `:telemetry.span/3`
      # gives the stop event only what the span function returns, so an action that fails
      # to hand its start metadata back still produces a correctly named metric --
      # tagged "unknown".
      duration = metric("pipeline.action.duration")
      assert %{"Values" => [_ | _]} = duration
      assert dimensions(duration) == %{"Action" => "CreateTranscodeJob"}

      count = metric("pipeline.action.count")
      assert dimensions(count) == %{"Action" => "CreateTranscodeJob", "Outcome" => "ok"}

      assert outcomes() == %{"ok" => 1}

      # A skipped action never reaches the action's own process/2, so it is counted but
      # contributes no duration sample.
      capture_log(fn ->
        send_test_message(CreateTranscodeJob, %{file_set_id: file_set_id}, %{})
      end)

      assert outcomes() == %{"ok" => 1, "skip" => 1}
      assert Enum.sum(metric("pipeline.action.duration")["Counts"]) == 1

      skipped =
        Aggregator.preview()
        |> Enum.find(&(dimensions(&1)["Outcome"] == "skip"))

      assert dimensions(skipped)["Action"] == "CreateTranscodeJob"
    end

    defp metric(name), do: Enum.find(Aggregator.preview(), &(&1["MetricName"] == name))

    defp dimensions(datum),
      do: Enum.into(datum["Dimensions"], %{}, &{&1["Name"], &1["Value"]})

    defp outcomes do
      Aggregator.preview()
      |> Enum.filter(&(&1["MetricName"] == "pipeline.action.count"))
      |> Enum.into(%{}, fn datum ->
        outcome = Enum.find(datum["Dimensions"], &(&1["Name"] == "Outcome"))
        {outcome["Value"], datum["Value"]}
      end)
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
