defmodule Meadow.Pipeline.Actions.ExtractMediaMetadataTest do
  use Meadow.S3Case
  use Meadow.DataCase
  use Meadow.PipelineCase

  alias Meadow.Data.{ActionStates, FileSets}
  alias Meadow.Pipeline.Actions.ExtractMediaMetadata

  import ExUnit.CaptureLog

  @bucket @ingest_bucket
  @media_key "extract_media_metadata_test/small.m4v"
  @media_content "test/fixtures/small.m4v"
  @media_fixture %{bucket: @bucket, key: @media_key, content: File.read!(@media_content)}
  @missing_media_key "extract_media_metadata_test/missing_media.m4v"
  @tool_name "mediainfo"

  setup do
    media_file_set =
      file_set_fixture(%{
        id: "cecb1180-054e-4764-8d2b-8a46c6b777b2",
        accession_number: "1234",
        role: %{id: "A", scheme: "FILE_SET_ROLE"},
        core_metadata: %{
          location: "s3://#{@bucket}/#{@media_key}",
          original_filename: "small.m4v"
        }
      })

    missing_media_file_set =
      file_set_fixture(%{
        id: "bbcb54da-fb1d-48ed-8438-99a030431086",
        accession_number: "2314",
        role: %{id: "A", scheme: "FILE_SET_ROLE"},
        core_metadata: %{
          location: "s3://#{@bucket}/#{@missing_media_key}",
          original_filename: "missing.m4v"
        }
      })

    invalid_file_set =
      file_set_fixture(%{
        id: "979d3570-9dc9-4d3b-ac1b-ee5524ee0bd3",
        accession_number: "4321",
        role: %{id: "A", scheme: "FILE_SET_ROLE"},
        core_metadata: %{
          location: "invalid",
          original_filename: "small.m4v"
        }
      })

    {:ok,
     media_file_set_id: media_file_set.id,
     missing_media_file_set_id: missing_media_file_set.id,
     invalid_file_set_id: invalid_file_set.id}
  end

  @tag s3: [@media_fixture]
  describe "success with metadata" do
    test "process/2", %{media_file_set_id: file_set_id} do
      assert {:ok, %{id: ^file_set_id}, %{}} =
               send_test_message(ExtractMediaMetadata, %{file_set_id: file_set_id}, %{})

      assert(ActionStates.ok?(file_set_id, ExtractMediaMetadata))

      file_set = FileSets.get_file_set!(file_set_id)
      assert file_set.extracted_metadata |> is_map()

      with subject <- file_set.extracted_metadata |> Map.get("mediainfo") do
        assert Map.get(subject, "tool") == @tool_name
        assert Map.get(subject, "tool_version")

        assert [general, video, audio] = subject |> get_in(["value", "media", "track"])

        assert general["@type"] == "General"
        assert video["@type"] == "Video"
        assert audio["@type"] == "Audio"

        assert general |> Map.get("Title") == "Video Metadata Extraction Test"

        assert general |> Map.get("Description") ==
                 "Description of Video Metadata Extraction Test"
      end

      assert capture_log(fn ->
               send_test_message(ExtractMediaMetadata, %{file_set_id: file_set_id}, %{})
             end) =~ "Skipping #{ExtractMediaMetadata} for #{file_set_id} - already complete"
    end
  end

  describe "missing file" do
    test "process/2", %{missing_media_file_set_id: file_set_id} do
      assert {:error, _, %{error: message}} =
               send_test_message(ExtractMediaMetadata, %{file_set_id: file_set_id}, %{})

      assert message |> String.contains?("404 Not Found")

      assert ActionStates.error?(file_set_id, ExtractMediaMetadata)

      file_set = FileSets.get_file_set!(file_set_id)

      with extracted <- file_set.extracted_metadata do
        assert is_nil(extracted) || is_nil(Map.get(extracted, "mediainfo"))
      end

      assert capture_log(fn ->
               send_test_message(ExtractMediaMetadata, %{file_set_id: file_set_id}, %{})
             end) =~ "Skipping #{ExtractMediaMetadata} for #{file_set_id} - already complete"
    end
  end

  describe "file_set with invalid location fails" do
    test "process/2", %{invalid_file_set_id: file_set_id} do
      assert {:error, _, %{error: "Invalid location: invalid"}} =
               send_test_message(ExtractMediaMetadata, %{file_set_id: file_set_id}, %{})

      assert(ActionStates.ok?(file_set_id, ExtractMediaMetadata) == false)
    end
  end

  describe "overwrite flag" do
    @describetag s3: [@media_fixture]

    setup %{media_file_set_id: file_set_id} do
      send_test_message(ExtractMediaMetadata, %{file_set_id: file_set_id}, %{})
      ActionStates.get_states(file_set_id) |> Enum.each(&Repo.delete!/1)

      :ok
    end

    test "overwrite", %{media_file_set_id: file_set_id} do
      log =
        capture_log(fn ->
          assert {:ok, %{id: ^file_set_id}, %{}} =
                   send_test_message(ExtractMediaMetadata, %{file_set_id: file_set_id}, %{})

          assert(ActionStates.ok?(file_set_id, ExtractMediaMetadata))
        end)

      refute log =~ ~r/already complete without overwriting/
    end

    test "retain", %{media_file_set_id: file_set_id} do
      log =
        capture_log(fn ->
          assert {:ok, %{id: ^file_set_id}, %{}} =
                   send_test_message(ExtractMediaMetadata, %{file_set_id: file_set_id}, %{
                     overwrite: "false"
                   })

          assert(ActionStates.ok?(file_set_id, ExtractMediaMetadata))
        end)

      assert log =~ ~r/already complete without overwriting/
    end
  end
end
