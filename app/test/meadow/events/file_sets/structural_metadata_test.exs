defmodule Meadow.Events.FileSets.StructuralMetadataTest do
  use Meadow.BucketNames
  use Meadow.DataCase, async: false
  use Meadow.S3Case
  alias Meadow.Data.FileSets

  import Assertions
  import Meadow.TestHelpers

  @vtt_1 """
  WEBVTT

  00:00:00.000 --> 00:00:01.000
  Welcome to Meadow.
  """

  @vtt_2 """

  00:00:01.500 --> 00:00:03.000
  Thanks. It's great to be here.
  """

  @moduletag walex: [Meadow.Events.FileSets.StructuralMetadata]
  describe "Meadow.Events.FileSets.StructuralMetadata" do
    setup do
      file_set = file_set_fixture()
      location = "s3://#{@pyramid_bucket}/#{FileSets.vtt_location(file_set.id)}"
      on_exit(fn -> delete_object(location) end)

      {:ok, file_set: file_set, location: location}
    end

    test "it creates a structural metadata file", %{file_set: file_set, location: location} do
      refute object_exists?(location)
      FileSets.update_file_set(file_set, %{structural_metadata: %{type: "webvtt", value: @vtt_1}})

      assert_async(timeout: 2000) do
        assert object_exists?(location)
        assert object_content(location) == @vtt_1
      end
    end

    test "it updates a structural metadata file", %{file_set: file_set, location: location} do
      vtt = @vtt_1
      FileSets.update_file_set(file_set, %{structural_metadata: %{type: "webvtt", value: vtt}})

      assert_async(timeout: 2000) do
        assert object_exists?(location)
        assert object_content(location) == vtt
      end

      vtt = @vtt_1 <> @vtt_2
      FileSets.update_file_set(file_set, %{structural_metadata: %{type: "webvtt", value: vtt}})

      assert_async(timeout: 2000) do
        assert object_exists?(location)
        assert object_content(location) == vtt
      end
    end
  end
end
