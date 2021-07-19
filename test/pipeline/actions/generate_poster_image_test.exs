defmodule Meadow.Pipeline.Actions.GeneratePosterImageTest do
  use Meadow.DataCase
  use Meadow.S3Case
  alias Meadow.Pipeline.Actions.GeneratePosterImage

  describe "file set exists with no playlist uri" do
    setup do
      file_set =
        file_set_fixture(
          role: %{id: "A", scheme: "FILE_SET_ROLE"},
          core_metadata: %{
            mime_type: "video/mov",
            location: "s3://test-ingest/small.m4v",
            original_filename: "small.m4v"
          }
        )

      upload_object("test-ingest", "small.m4v", File.read!("test/fixtures/small.m4v"))

      on_exit(fn ->
        delete_object("test-ingest", "small.m4v")
        empty_bucket("test-ingest")
      end)

      {:ok, file_set: file_set}
    end

    test "process/2", %{file_set: file_set} do
      assert(GeneratePosterImage.process(%{file_set_id: file_set.id}, %{offset: 100}) == :ok)
    end
  end
end
