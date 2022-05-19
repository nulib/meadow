defmodule Meadow.StructuralMetadataListenerTest do
  use Meadow.DataCase
  use Meadow.S3Case
  alias Meadow.Data.FileSets
  alias Meadow.StructuralMetadataListener

  @vtt """
  WEBVTT

  00:01.000 --> 00:04.000
  - Never drink liquid nitrogen.

  00:05.000 --> 00:09.000
  - It will perforate your stomach.
  - You could die.
  """

  setup do
    {:ok, file_set} =
      file_set_fixture()
      |> FileSets.update_file_set(%{structural_metadata: %{type: "webvtt", value: @vtt}})

    location = FileSets.vtt_location(file_set.id)
    on_exit(fn -> delete_object(@pyramid_bucket, location) end)
    {:ok, %{file_set: file_set, location: location}}
  end

  describe "create structural metadata file" do
    test "when file set is updated", %{file_set: file_set, location: location} do
      refute object_exists?(@pyramid_bucket, location)
      StructuralMetadataListener.handle_notification(:file_sets, :update, %{id: file_set.id}, nil)
      assert object_exists?(@pyramid_bucket, location)
      assert object_size(@pyramid_bucket, location) == byte_size(@vtt)
    end

    test "when file set is created" do
      file_set = file_set_fixture(%{structural_metadata: %{type: "webvtt", value: @vtt}})
      StructuralMetadataListener.handle_notification(:file_sets, :create, %{id: file_set.id}, nil)

      assert object_exists?(@pyramid_bucket, FileSets.vtt_location(file_set.id))
      assert object_size(@pyramid_bucket, FileSets.vtt_location(file_set.id)) == byte_size(@vtt)
    end
  end

  describe "delete structural metadata file" do
    setup %{file_set: file_set} do
      StructuralMetadataListener.handle_notification(:file_sets, :update, %{id: file_set.id}, nil)
      {:ok, %{file_set: file_set}}
    end

    test "when structural_metadata.value is nil", %{file_set: file_set, location: location} do
      assert object_exists?(@pyramid_bucket, location)
      file_set |> FileSets.update_file_set(%{structural_metadata: %{value: nil}})
      StructuralMetadataListener.handle_notification(:file_sets, :update, %{id: file_set.id}, nil)
      refute object_exists?(@pyramid_bucket, location)
    end

    test "when structural_metadata is nil", %{file_set: file_set, location: location} do
      assert object_exists?(@pyramid_bucket, location)
      file_set |> FileSets.update_file_set(%{structural_metadata: nil})
      StructuralMetadataListener.handle_notification(:file_sets, :update, %{id: file_set.id}, nil)
      refute object_exists?(@pyramid_bucket, location)
    end

    test "when file set is deleted", %{file_set: file_set, location: location} do
      assert object_exists?(@pyramid_bucket, location)
      file_set |> FileSets.delete_file_set()
      StructuralMetadataListener.handle_notification(:file_sets, :delete, %{id: file_set.id}, nil)
      refute object_exists?(@pyramid_bucket, location)
    end
  end
end
