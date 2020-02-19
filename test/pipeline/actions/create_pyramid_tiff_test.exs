defmodule Meadow.Pipeline.Actions.CreatePyramidTiffTest do
  use Meadow.DataCase
  use Meadow.S3Case
  alias Meadow.Data.ActionStates
  alias Meadow.Pipeline.Actions.CreatePyramidTiff
  alias Meadow.Utils.Pairtree
  import ExUnit.CaptureLog

  @bucket "test-ingest"
  @key "create_pyramid_tiff_test/coffee.tif"
  @content "test/fixtures/coffee.tif"
  @fixture %{bucket: @bucket, key: @key, content: File.read!(@content)}

  setup do
    file_set =
      file_set_fixture(%{
        id: "6caf2759-c476-46ae-9c40-ec58cf44c704",
        accession_number: "123",
        role: "am",
        metadata: %{
          location: "s3://#{@bucket}/#{@key}",
          original_filename: "coffee.tif"
        }
      })

    {:ok, file_set_id: file_set.id, pairtree: Pairtree.generate_pyramid_path(file_set.id)}
  end

  @tag s3: [@fixture]
  describe "success" do
    test "process/2", %{file_set_id: file_set_id, pairtree: dest} do
      assert(CreatePyramidTiff.process(%{file_set_id: file_set_id}, %{}) == :ok)
      assert(ActionStates.ok?(file_set_id, CreatePyramidTiff))
      assert {:ok, _} = ExAws.S3.head_object("test-pyramids", dest) |> ExAws.request()

      assert capture_log(fn ->
               CreatePyramidTiff.process(%{file_set_id: file_set_id}, %{})
             end) =~ "Skipping #{CreatePyramidTiff} for #{file_set_id} – already complete"
    end
  end
end
