defmodule Meadow.Pipeline.Actions.ExtractMimeTypeTest do
  use Meadow.DataCase
  use Meadow.S3Case
  alias Meadow.Data.{ActionStates, FileSets}
  alias Meadow.Pipeline.Actions.ExtractMimeType
  import ExUnit.CaptureLog

  @bucket @ingest_bucket
  @good_tiff "coffee.tif"
  @bad_tiff "not_a_tiff.tif"
  @json_file "details.json"
  @framemd5_file "supplemental_file.framemd5"
  @matroska "sample.mkv"
  @good_xml "good_xml.xml"
  @no_declaration_xml "no_declaration.xml"
  @random_file "random.blergh"

  setup tags do
    key = Path.join("extract_mime_type_test", tags[:fixture_file])
    upload_object(@bucket, key, File.read!(Path.join("test/fixtures", tags[:fixture_file])))
    on_exit(fn -> delete_object(@bucket, key) end)

    file_set =
      file_set_fixture(%{
        accession_number: "123",
        role: %{id: tags[:file_set_role_id], scheme: "FILE_SET_ROLE"},
        core_metadata: %{
          location: "s3://#{@bucket}/#{key}",
          original_filename: tags[:fixture_file]
        }
      })

    {:ok, file_set_id: file_set.id}
  end

  describe "process/2" do
    @tag fixture_file: @good_tiff, file_set_role_id: "P"
    test "good tiff", %{file_set_id: file_set_id} do
      assert(ExtractMimeType.process(%{file_set_id: file_set_id}, %{}) == :ok)
      assert(ActionStates.ok?(file_set_id, ExtractMimeType))

      file_set = FileSets.get_file_set!(file_set_id)
      assert(file_set.core_metadata.mime_type == "image/tiff")

      assert capture_log(fn ->
               ExtractMimeType.process(%{file_set_id: file_set_id}, %{})
             end) =~ "Skipping #{ExtractMimeType} for #{file_set_id} - already complete"
    end

    @tag fixture_file: @bad_tiff, file_set_role_id: "P"
    test "bad tiff", %{file_set_id: file_set_id} do
      log =
        capture_log(fn ->
          assert({:error, _} = ExtractMimeType.process(%{file_set_id: file_set_id}, %{}))
          assert(ActionStates.error?(file_set_id, ExtractMimeType))
        end)

      assert log =~ ~r/Received undefined response from lambda/
      assert log =~ ~r"not_a_tiff.tif appears to be image/tiff but magic number doesn't match."
    end

    @tag fixture_file: @json_file, file_set_role_id: "P"
    test "non-binary content", %{file_set_id: file_set_id} do
      assert(ExtractMimeType.process(%{file_set_id: file_set_id}, %{}) == :ok)
      assert(ActionStates.ok?(file_set_id, ExtractMimeType))

      file_set = FileSets.get_file_set!(file_set_id)
      assert(file_set.core_metadata.mime_type == "application/json")

      assert capture_log(fn ->
               ExtractMimeType.process(%{file_set_id: file_set_id}, %{})
             end) =~ "Skipping #{ExtractMimeType} for #{file_set_id} - already complete"
    end

    @tag fixture_file: @framemd5_file, file_set_role_id: "S"
    test "MIME extractor recognizes framemd5 file", %{file_set_id: file_set_id} do
      ExtractMimeType.process(%{file_set_id: file_set_id}, %{})
      assert(ActionStates.ok?(file_set_id, ExtractMimeType))

      file_set = FileSets.get_file_set!(file_set_id)
      assert(file_set.core_metadata.mime_type == "text/plain")
    end

    @tag fixture_file: @random_file, file_set_role_id: "S"
    test "supplemental file falls back to application/octet-stream", %{file_set_id: file_set_id} do
      ExtractMimeType.process(%{file_set_id: file_set_id}, %{})
      assert(ActionStates.ok?(file_set_id, ExtractMimeType))

      file_set = FileSets.get_file_set!(file_set_id)
      assert(file_set.core_metadata.mime_type == "application/octet-stream")
    end

    @tag fixture_file: @matroska, file_set_role_id: "P"
    test "Matroska (MKV) preservation file", %{file_set_id: file_set_id} do
      assert(ExtractMimeType.process(%{file_set_id: file_set_id}, %{}) == :ok)
      assert(ActionStates.ok?(file_set_id, ExtractMimeType))

      file_set = FileSets.get_file_set!(file_set_id)
      assert(file_set.core_metadata.mime_type == "video/x-matroska")

      assert capture_log(fn ->
               ExtractMimeType.process(%{file_set_id: file_set_id}, %{})
             end) =~ "Skipping #{ExtractMimeType} for #{file_set_id} - already complete"
    end

    @tag fixture_file: @good_xml, file_set_role_id: "S"
    test "well-formed XML with declaration", %{file_set_id: file_set_id} do
      assert(ExtractMimeType.process(%{file_set_id: file_set_id}, %{}) == :ok)
      assert(ActionStates.ok?(file_set_id, ExtractMimeType))

      file_set = FileSets.get_file_set!(file_set_id)
      assert(file_set.core_metadata.mime_type == "application/xml")

      assert capture_log(fn ->
               ExtractMimeType.process(%{file_set_id: file_set_id}, %{})
             end) =~ "Skipping #{ExtractMimeType} for #{file_set_id} - already complete"
    end

    @tag fixture_file: @no_declaration_xml, file_set_role_id: "S"
    test "well-formed XML without declaration", %{file_set_id: file_set_id} do
      assert(ExtractMimeType.process(%{file_set_id: file_set_id}, %{}) == :ok)
      assert(ActionStates.ok?(file_set_id, ExtractMimeType))

      file_set = FileSets.get_file_set!(file_set_id)
      assert(file_set.core_metadata.mime_type == "application/xml")

      assert capture_log(fn ->
               ExtractMimeType.process(%{file_set_id: file_set_id}, %{})
             end) =~ "Skipping #{ExtractMimeType} for #{file_set_id} - already complete"
    end
  end
end
