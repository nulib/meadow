defmodule Meadow.Pipeline.Actions.GeneratePosterImageTest do
  use Meadow.DataCase
  use Meadow.S3Case
  alias Meadow.Pipeline.Actions.GeneratePosterImage

  describe "file set exists" do
    setup do
      upload_object("test-streaming", "small.m4v", File.read!("test/fixtures/small.m4v"))

      on_exit(fn ->
        delete_object("test-streaming", "small.m4v")
        empty_bucket("test-streaming")
      end)

      :ok
    end

    test "process/2" do
      object =
        file_set_fixture(
          role: %{id: "A", scheme: "FILE_SET_ROLE"},
          core_metadata: %{
            mime_type: "video/mov",
            location: "s3://test-ingest/small.m4v",
            original_filename: "small.m4v"
          }
        )

      assert(GeneratePosterImage.process(%{file_set_id: object.id}, %{key: "small.m4v", offset: 100}) == :ok)
    end
  end
end
