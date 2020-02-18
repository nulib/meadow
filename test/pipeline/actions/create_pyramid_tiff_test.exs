defmodule Meadow.Pipeline.Actions.CreatePyramidTiffTest do
  use Meadow.DataCase
  alias Meadow.Data.{ActionStates, FileSets}
  alias Meadow.Pipeline.Actions.CreatePyramidTiff
  alias Meadow.Utils.Pairtree
  import ExUnit.CaptureLog

  @bucket "test-ingest"
  @key "project-123/coffee.tif"
  @fixture "test/fixtures/coffee.tif"

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

    ExAws.S3.put_object(@bucket, @key, File.read!(@fixture)) |> ExAws.request!()

    {:ok, file_set_id: file_set.id, pairtree: Pairtree.generate_pyramid_path(file_set.id)}
  end

  describe "success" do
    test "process/2", %{file_set_id: file_set_id, pairtree: dest} do
      assert(CreatePyramidTiff.process(%{file_set_id: file_set_id}, %{}) == :ok)
      assert(ActionStates.ok?(file_set_id, CreatePyramidTiff))
      assert {:ok, _} = ExAws.S3.head_object("test-pyramids", dest) |> ExAws.request()
    end
  end
end
