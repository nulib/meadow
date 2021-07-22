defmodule Meadow.Pipeline.Actions.GeneratePosterImageTest do
  use Meadow.DataCase
  use Meadow.S3Case
  alias Meadow.Data.FileSets
  alias Meadow.Pipeline.Actions.GeneratePosterImage
  alias Meadow.Utils.Pairtree

  describe "file set exists with a playlist uri" do
    setup do
      file_set = file_set_fixture(role: %{id: "A", scheme: "FILE_SET_ROLE"})
      ts = "/" <> Pairtree.generate!(file_set.id) <> "/test.ts"
      m3u8 = "/" <> Pairtree.generate!(file_set.id) <> "/test.m3u8"
      m3u8_uri = FileSets.streaming_uri_for(file_set.id) <> "test.m3u8"

      {:ok, file_set_with_playlist} =
        FileSets.update_file_set(file_set, %{derivatives: %{"playlist" => m3u8_uri}})

      upload_object("test-streaming", m3u8, File.read!("test/fixtures/test.m3u8"))
      upload_object("test-streaming", ts, File.read!("test/fixtures/test.ts"))

      on_exit(fn ->
        delete_object("test-streaming", ts)
        delete_object("test-streaming", m3u8)
        empty_bucket("test-streaming")
      end)

      {:ok, file_set: file_set_with_playlist}
    end

    test "process/2", %{file_set: file_set} do
      assert(GeneratePosterImage.process(%{file_set_id: file_set.id}, %{offset: 7000}) == :ok)
    end
  end

  describe "file set exists with no playlist" do
    setup do
      file_set =
        file_set_fixture(
          role: %{id: "A", scheme: "FILE_SET_ROLE"},
          core_metadata: %{
            mime_type: "video/mov",
            location: "s3://test-ingest/small.m4v",
            original_filename: "small.m4v"
          },
          derivatives: %{"playlist" => "s3://test-streaming/foo/bar.m4v"}
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
