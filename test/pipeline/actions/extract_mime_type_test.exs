defmodule Meadow.Pipeline.Actions.ExtractMimeTypeTest do
  use Meadow.S3Case
  use Meadow.DataCase
  alias Meadow.Data.{ActionStates, FileSets}
  alias Meadow.Pipeline.Actions.ExtractMimeType
  import ExUnit.CaptureLog

  @bucket "test-ingest"
  @key "generate_file_set_digests_test/test.tif"
  @good_content "test/fixtures/coffee.tif"
  @bad_content "test/fixtures/not_a_tiff.tif"

  setup do
    file_set =
      file_set_fixture(%{
        accession_number: "123",
        role: %{id: "P", scheme: "FILE_SET_ROLE"},
        core_metadata: %{
          location: "s3://#{@bucket}/#{@key}",
          original_filename: "test.tif"
        }
      })

    {:ok, file_set_id: file_set.id}
  end

  describe "process/2" do
    @tag s3: [%{bucket: @bucket, key: @key, content: File.read!(@good_content)}]
    test "good content", %{file_set_id: file_set_id} do
      assert(ExtractMimeType.process(%{file_set_id: file_set_id}, %{}) == :ok)
      assert(ActionStates.ok?(file_set_id, ExtractMimeType))

      file_set = FileSets.get_file_set!(file_set_id)
      assert(file_set.core_metadata.mime_type == "image/tiff")

      assert capture_log(fn ->
               ExtractMimeType.process(%{file_set_id: file_set_id}, %{})
             end) =~ "Skipping #{ExtractMimeType} for #{file_set_id} – already complete"
    end

    @tag s3: [%{bucket: @bucket, key: @key, content: File.read!(@bad_content)}]
    test "bad content", %{file_set_id: file_set_id} do
      log =
        capture_log(fn ->
          assert({:error, _} = ExtractMimeType.process(%{file_set_id: file_set_id}, %{}))
          assert(ActionStates.error?(file_set_id, ExtractMimeType))
        end)

      assert log =~ ~r/Received undefined response from lambda/
    end
  end
end
