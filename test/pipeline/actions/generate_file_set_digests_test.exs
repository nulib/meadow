defmodule Meadow.Pipeline.Actions.GenerateFileSetDigestsTest do
  use Meadow.S3Case
  use Meadow.DataCase
  alias Meadow.Data.{ActionStates, FileSets}
  alias Meadow.Pipeline.Actions.GenerateFileSetDigests
  import ExUnit.CaptureLog

  @bucket "test-ingest"
  @key "generate_file_set_digests_test/test.tif"
  @content "test/fixtures/ingest_sheet.csv"
  @fixture %{bucket: @bucket, key: @key, content: File.read!(@content)}
  @sha256 "3be2b0180066d23605f9f022ae68facecc7f11e557e88dea3219bb4d42e150b5"

  setup do
    file_set =
      file_set_fixture(%{
        accession_number: "123",
        role: "am",
        metadata: %{
          location: "s3://#{@bucket}/#{@key}",
          original_filename: "test.tif"
        }
      })

    {:ok, file_set_id: file_set.id}
  end

  @tag s3: [@fixture]
  test "process/2", %{file_set_id: file_set_id} do
    assert(GenerateFileSetDigests.process(%{file_set_id: file_set_id}, %{}) == :ok)
    assert(ActionStates.ok?(file_set_id, GenerateFileSetDigests))

    file_set = FileSets.get_file_set!(file_set_id)
    assert(file_set.metadata.digests == %{"sha256" => @sha256})

    assert capture_log(fn ->
             GenerateFileSetDigests.process(%{file_set_id: file_set_id}, %{})
           end) =~ "Skipping #{GenerateFileSetDigests} for #{file_set_id} – already complete"
  end
end
