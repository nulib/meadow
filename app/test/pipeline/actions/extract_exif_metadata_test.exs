defmodule Meadow.Pipeline.Actions.ExtractExifMetadataTest do
  use Meadow.S3Case
  use Meadow.DataCase
  use Meadow.PipelineCase

  alias Meadow.Data.{ActionStates, FileSets}
  alias Meadow.Pipeline.Actions.ExtractExifMetadata

  import Assertions
  import ExUnit.CaptureLog

  @bucket @ingest_bucket
  @exif_key "extract_exif_metadata_test/exif.tif"
  @exif_content "test/fixtures/coffee.tif"
  @exif_fixture %{bucket: @bucket, key: @exif_key, content: File.read!(@exif_content)}
  @no_exif_key "extract_exif_metadata_test/no_exif.jpg"
  @no_exif_content "test/fixtures/no_exif_metadata.jpg"
  @no_exif_fixture %{bucket: @bucket, key: @no_exif_key, content: File.read!(@no_exif_content)}
  @exif %{
    "Artist" => "Artist Name",
    "BitsPerSample" => "8 8 8",
    "Compression" => "Uncompressed",
    "Copyright" => "In Copyright",
    "FillOrder" => "Normal",
    "ImageDescription" =>
      "inu-wint-58.6, 8/20/07, 11:16 AM,  8C, 9990x9750 (0+3570), 125%, bent 6 b/w adj,  1/30 s, R43.0, G4.4, B12.6",
    "ImageHeight" => 1024,
    "ImageWidth" => 1024,
    "Make" => "Better Light",
    "Model" => "Model Super8K",
    "Orientation" => "Horizontal (normal)",
    "PhotometricInterpretation" => "RGB",
    "PlanarConfiguration" => "Chunky",
    "ResolutionUnit" => "inches",
    "SamplesPerPixel" => 3,
    "Software" => "Adobe Photoshop CC 2015.5 (Windows)",
    "SourceFile" => "-",
    "XResolution" => 72,
    "YResolution" => 72
  }
  @keys ~w(Artist
           BitsPerSample
           Compression
           FillOrder
           ImageDescription
           ImageHeight
           ImageWidth
           Make
           Model
           Orientation
           PhotometricInterpretation
           PlanarConfiguration
           ResolutionUnit
           SamplesPerPixel
           Software
           XResolution
           YResolution)
  @tool_name "exiftool"

  setup do
    exif_file_set =
      file_set_fixture(%{
        id: "cecb1180-054e-4764-8d2b-8a46c6b777b2",
        accession_number: "1234",
        role: %{id: "A", scheme: "FILE_SET_ROLE"},
        core_metadata: %{
          location: "s3://#{@bucket}/#{@exif_key}",
          original_filename: "test.tif"
        }
      })

    no_exif_file_set =
      file_set_fixture(%{
        id: "bbcb54da-fb1d-48ed-8438-99a030431086",
        accession_number: "2314",
        role: %{id: "A", scheme: "FILE_SET_ROLE"},
        core_metadata: %{
          location: "s3://#{@bucket}/#{@no_exif_key}",
          original_filename: "test.tif"
        }
      })

    invalid_file_set =
      file_set_fixture(%{
        id: "979d3570-9dc9-4d3b-ac1b-ee5524ee0bd3",
        accession_number: "4321",
        role: %{id: "A", scheme: "FILE_SET_ROLE"},
        core_metadata: %{
          location: "invalid",
          original_filename: "test.tif"
        }
      })

    {:ok,
     exif_file_set_id: exif_file_set.id,
     no_exif_file_set_id: no_exif_file_set.id,
     invalid_file_set_id: invalid_file_set.id}
  end

  describe "success with EXIF metadata" do
    @describetag s3: [@exif_fixture]

    test "process/2", %{exif_file_set_id: file_set_id} do
      assert {:ok, %{id: ^file_set_id}, %{}} =
               send_test_message(ExtractExifMetadata, %{file_set_id: file_set_id}, %{})

      assert(ActionStates.ok?(file_set_id, ExtractExifMetadata))

      file_set = FileSets.get_file_set!(file_set_id)
      assert file_set.extracted_metadata |> is_map()

      with subject <- file_set.extracted_metadata |> Map.get("exif") do
        assert Map.get(subject, "tool") == @tool_name
        assert Map.get(subject, "tool_version")
        assert_maps_equal(Map.get(subject, "value"), @exif, @keys)
      end
    end
  end

  describe "success without EXIF metadata" do
    @describetag s3: [@no_exif_fixture]

    test "process/2", %{no_exif_file_set_id: file_set_id} do
      assert {:ok, %{id: ^file_set_id}, %{}} =
               send_test_message(ExtractExifMetadata, %{file_set_id: file_set_id}, %{})

      assert(ActionStates.ok?(file_set_id, ExtractExifMetadata))

      file_set = FileSets.get_file_set!(file_set_id)

      case file_set.extracted_metadata do
        nil ->
          assert true

        %{"exif" => nil} ->
          assert true

        %{"exif" => %{"value" => map}} ->
          assert_lists_equal(Map.keys(map), ~w(BitsPerSample ImageHeight ImageWidth))

        _ ->
          assert false
      end
    end
  end

  describe "file_set with invalid location fails" do
    test "process/2", %{invalid_file_set_id: file_set_id} do
      assert {:error, _, %{error: "Invalid location: invalid"}} =
               send_test_message(ExtractExifMetadata, %{file_set_id: file_set_id}, %{})

      assert(ActionStates.ok?(file_set_id, ExtractExifMetadata) == false)
    end
  end

  describe "force flag" do
    @describetag s3: [@exif_fixture]

    setup %{exif_file_set_id: file_set_id} do
      send_test_message(ExtractExifMetadata, %{file_set_id: file_set_id}, %{})

      :ok
    end

    test "skip if not forced", %{exif_file_set_id: file_set_id} do
      assert(ActionStates.ok?(file_set_id, ExtractExifMetadata))

      assert capture_log(fn ->
               send_test_message(ExtractExifMetadata, %{file_set_id: file_set_id}, %{})
             end) =~ "Skipping #{ExtractExifMetadata} for #{file_set_id} - already complete"
    end

    test "re-run if forced", %{exif_file_set_id: file_set_id} do
      assert(ActionStates.ok?(file_set_id, ExtractExifMetadata))

      assert capture_log(fn ->
               send_test_message(ExtractExifMetadata, %{file_set_id: file_set_id}, %{
                 force: "true"
               })
             end) =~
               "Forcing #{ExtractExifMetadata} for #{file_set_id} even though it's already complete"
    end
  end

  describe "overwrite flag" do
    @describetag s3: [@exif_fixture]

    setup %{exif_file_set_id: file_set_id} do
      send_test_message(ExtractExifMetadata, %{file_set_id: file_set_id}, %{})
      ActionStates.get_states(file_set_id) |> Enum.each(&Repo.delete!/1)

      :ok
    end

    test "overwrite", %{exif_file_set_id: file_set_id} do
      log =
        capture_log(fn ->
          assert {:ok, %{id: ^file_set_id}, %{}} =
                   send_test_message(ExtractExifMetadata, %{file_set_id: file_set_id}, %{})

          assert(ActionStates.ok?(file_set_id, ExtractExifMetadata))
        end)

      refute log =~ ~r/already complete without overwriting/
    end

    test "retain", %{exif_file_set_id: file_set_id} do
      log =
        capture_log(fn ->
          assert {:ok, %{id: ^file_set_id}, %{}} =
                   send_test_message(ExtractExifMetadata, %{file_set_id: file_set_id}, %{
                     overwrite: "false"
                   })

          assert(ActionStates.ok?(file_set_id, ExtractExifMetadata))
        end)

      assert log =~ ~r/already complete without overwriting/
    end

    test "key collision", %{exif_file_set_id: file_set_id} do
      with file_set <- FileSets.get_file_set!(file_set_id) do
        extracted_metadata = put_in(file_set.extracted_metadata, ["exif", "value"], "bogus")
        FileSets.update_file_set(file_set, %{extracted_metadata: extracted_metadata})
      end

      with %{extracted_metadata: subject} <- FileSets.get_file_set!(file_set_id) do
        assert get_in(subject, ["exif", "value"]) == "bogus"
      end

      assert {:ok, %{id: ^file_set_id}, %{}} =
               send_test_message(ExtractExifMetadata, %{file_set_id: file_set_id}, %{})

      FileSets.get_file_set!(file_set_id)
      |> Map.get(:extracted_metadata)
      |> get_in(["exif", "value"])
      |> assert_maps_equal(@exif, @keys)
    end
  end
end
