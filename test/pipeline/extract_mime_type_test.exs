defmodule Meadow.Pipeline.Actions.ExtractMimeTypeTest do
  use Meadow.S3Case
  use Meadow.DataCase
  alias Meadow.Data.{ActionStates, FileSets}
  alias Meadow.Pipeline.Actions.ExtractMimeType
  import ExUnit.CaptureLog

  @bucket "test-ingest"
  @key "generate_file_set_digests_test/test.tif"
  @content "test/fixtures/coffee.tif"
  @fixture %{bucket: @bucket, key: @key, content: File.read!(@content)}

  setup do
    file_set =
      file_set_fixture(%{
        accession_number: "123",
        role: "pm",
        metadata: %{
          location: "s3://#{@bucket}/#{@key}",
          original_filename: "test.tif"
        }
      })

    {:ok, file_set_id: file_set.id}
  end

  @tag s3: [@fixture]
  test "process/2", %{file_set_id: file_set_id} do
    assert(ExtractMimeType.process(%{file_set_id: file_set_id}, %{}) == :ok)
    assert(ActionStates.ok?(file_set_id, ExtractMimeType))

    file_set = FileSets.get_file_set!(file_set_id)
    assert(file_set.metadata.mime_type == "image/tiff")

    assert capture_log(fn ->
             ExtractMimeType.process(%{file_set_id: file_set_id}, %{})
           end) =~ "Skipping #{ExtractMimeType} for #{file_set_id} – already complete"
  end
end
