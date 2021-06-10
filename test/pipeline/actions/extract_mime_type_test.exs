defmodule Meadow.Pipeline.Actions.ExtractMimeTypeTest do
  use Meadow.S3Case
  use Meadow.DataCase
  alias Meadow.Data.{ActionStates, FileSets}
  alias Meadow.Pipeline.Actions.ExtractMimeType
  import ExUnit.CaptureLog

  @bucket "test-ingest"
  @good_tiff "coffee.tif"
  @bad_tiff "not_a_tiff.tif"
  @json_file "details.json"

  setup tags do
    key = Path.join("extract_mime_type_test", tags[:fixture_file])
    upload_object(@bucket, key, File.read!(Path.join("test/fixtures", tags[:fixture_file])))
    on_exit(fn -> delete_object(@bucket, key) end)

    file_set =
      file_set_fixture(%{
        accession_number: "123",
        role: %{id: "P", scheme: "FILE_SET_ROLE"},
        core_metadata: %{
          location: "s3://#{@bucket}/#{key}",
          original_filename: tags[:fixture_file]
        }
      })

    {:ok, file_set_id: file_set.id}
  end

  describe "process/2" do
    @tag fixture_file: @good_tiff
    test "good tiff", %{file_set_id: file_set_id} do
      assert(ExtractMimeType.process(%{file_set_id: file_set_id}, %{}) == :ok)
      assert(ActionStates.ok?(file_set_id, ExtractMimeType))

      file_set = FileSets.get_file_set!(file_set_id)
      assert(file_set.core_metadata.mime_type == "image/tiff")

      assert capture_log(fn ->
               ExtractMimeType.process(%{file_set_id: file_set_id}, %{})
             end) =~ "Skipping #{ExtractMimeType} for #{file_set_id} – already complete"
    end

    @tag fixture_file: @bad_tiff
    test "bad tiff", %{file_set_id: file_set_id} do
      log =
        capture_log(fn ->
          assert({:error, _} = ExtractMimeType.process(%{file_set_id: file_set_id}, %{}))
          assert(ActionStates.error?(file_set_id, ExtractMimeType))
        end)

      assert log =~ ~r/Received undefined response from lambda/
      assert log =~ ~r"not_a_tiff.tif appears to be image/tiff but magic number doesn't match."
    end

    @tag fixture_file: @json_file
    test "non-binary content", %{file_set_id: file_set_id} do
      assert(ExtractMimeType.process(%{file_set_id: file_set_id}, %{}) == :ok)
      assert(ActionStates.ok?(file_set_id, ExtractMimeType))

      file_set = FileSets.get_file_set!(file_set_id)
      assert(file_set.core_metadata.mime_type == "application/json")

      assert capture_log(fn ->
               ExtractMimeType.process(%{file_set_id: file_set_id}, %{})
             end) =~ "Skipping #{ExtractMimeType} for #{file_set_id} – already complete"
    end
  end
end
