defmodule Meadow.Ingest.Actions.GenerateFileSetDigestsTest do
  use Meadow.S3Case
  use Meadow.DataCase
  alias Meadow.Data.FileSets
  alias Meadow.Ingest.Actions.GenerateFileSetDigests

  @bucket "test-ingest"
  @key "project-123/test.tif"
  @fixture "test/fixtures/ingest_sheet.csv"
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

  @tag [
    bucket: @bucket,
    key: @key,
    chunk_size: 1024,
    content: File.read!(@fixture)
  ]
  test "process/2", %{file_set_id: file_set_id} do
    assert(GenerateFileSetDigests.process(%{file_set_id: file_set_id}, %{}) == :ok)

    file_set = FileSets.get_file_set!(file_set_id)
    assert(file_set.metadata.digests == %{"sha256" => @sha256})
  end
end
