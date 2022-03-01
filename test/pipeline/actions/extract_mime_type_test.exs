defmodule Meadow.Pipeline.Actions.ExtractMimeTypeTest do
  use Meadow.DataCase
  use Meadow.S3Case
  alias Meadow.Data.{ActionStates, FileSets}
  alias Meadow.Pipeline.Actions.ExtractMimeType
  import ExUnit.CaptureLog

  @bucket "test-ingest"
  @good_tiff "coffee.tif"
  @bad_tiff "not_a_tiff.tif"
  @json_file "details.json"
  @framemd5_file "supplemental_file.framemd5"
  @good_xml "good_xml.xml"
  @bad_xml "bad_xml.xml"
  @no_declaration_xml "no_declaration.xml"

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
    test "supplemental file falls back to application/octet-stream", %{file_set_id: file_set_id} do
      ExtractMimeType.process(%{file_set_id: file_set_id}, %{})
      assert(ActionStates.ok?(file_set_id, ExtractMimeType))

      file_set = FileSets.get_file_set!(file_set_id)
      assert(file_set.core_metadata.mime_type == "application/octet-stream")
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
      log =
        capture_log(fn ->
          assert(ExtractMimeType.process(%{file_set_id: file_set_id}, %{}) == :ok)
        end)

      assert(ActionStates.ok?(file_set_id, ExtractMimeType))

      assert log
             |> String.contains?(
               "Confirming extract_mime_type_test/#{@no_declaration_xml} is well-formed XML"
             )

      file_set = FileSets.get_file_set!(file_set_id)
      assert(file_set.core_metadata.mime_type == "application/xml")

      assert capture_log(fn ->
               ExtractMimeType.process(%{file_set_id: file_set_id}, %{})
             end) =~ "Skipping #{ExtractMimeType} for #{file_set_id} - already complete"
    end

    @tag fixture_file: @bad_xml, file_set_role_id: "S"
    test "corrupt XML", %{file_set_id: file_set_id} do
      log =
        capture_log(fn ->
          assert(
            ExtractMimeType.process(%{file_set_id: file_set_id}, %{}) ==
              {:error, "error in mime-type extraction"}
          )
        end)

      assert(ActionStates.error?(file_set_id, ExtractMimeType))

      assert log |> String.contains?("InvalidXml:")
      assert log |> String.contains?("appears to be application/xml but is not valid XML")

      file_set = FileSets.get_file_set!(file_set_id)
      assert(file_set.core_metadata.mime_type |> is_nil)

      assert capture_log(fn ->
               ExtractMimeType.process(%{file_set_id: file_set_id}, %{})
             end) =~ "Skipping #{ExtractMimeType} for #{file_set_id} - already complete"
    end
  end
end
