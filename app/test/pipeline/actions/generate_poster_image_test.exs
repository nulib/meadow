defmodule Meadow.Pipeline.Actions.GeneratePosterImageTest do
  use Meadow.S3Case
  use Meadow.DataCase
  use Meadow.PipelineCase

  alias Meadow.Config.Secrets
  alias Meadow.Data.FileSets
  alias Meadow.Pipeline.Actions.GeneratePosterImage
  alias Meadow.Utils.Pairtree

  import ExUnit.CaptureLog

  @mediainfo %{
    "mediainfo" => %{
      "tool" => "mediainfo",
      "value" => %{
        "media" => %{
          "track" => [
            %{
              "@type" => "General",
              "Duration" => "1000.999"
            }
          ]
        }
      }
    }
  }

  describe "file set exists with a playlist uri and offset within duration range" do
    setup do
      file_set =
        file_set_fixture(
          role: %{id: "A", scheme: "FILE_SET_ROLE"},
          extracted_metadata: @mediainfo,
          poster_offset: 4_000
        )

      ts = "/" <> Pairtree.generate!(file_set.id) <> "/test.ts"
      m3u8 = "/" <> Pairtree.generate!(file_set.id) <> "/test-1080.m3u8"
      adaptive = "/" <> Pairtree.generate!(file_set.id) <> "/test.m3u8"
      m3u8_uri = FileSets.streaming_uri_for(file_set.id) <> "test.m3u8"

      {:ok, file_set_with_playlist} =
        FileSets.update_file_set(file_set, %{derivatives: %{"playlist" => m3u8_uri}})

      upload_object(@streaming_bucket, m3u8, File.read!("test/fixtures/test-1080.m3u8"))
      upload_object(@streaming_bucket, adaptive, File.read!("test/fixtures/test.m3u8"))
      upload_object(@streaming_bucket, ts, File.read!("test/fixtures/test.ts"))

      on_exit(fn ->
        empty_bucket(@pyramid_bucket)
        empty_bucket(@streaming_bucket)
      end)

      {:ok, file_set: file_set_with_playlist}
    end

    test "process/2", %{file_set: %{id: file_set_id} = file_set} do
      assert {:ok, %{id: ^file_set_id}, %{}} =
               send_test_message(GeneratePosterImage, %{file_set_id: file_set_id}, %{})

      assert(object_exists?(FileSets.poster_uri_for(file_set)))

      with {:ok, %{headers: headers}} <-
             ExAws.S3.head_object(@pyramid_bucket, "posters/#{Pairtree.poster_path(file_set.id)}")
             |> ExAws.request() do
        assert headers |> Enum.member?({"Content-Type", "image/tiff"})
        assert headers |> Enum.member?({"x-amz-meta-width", "1920"})
        assert headers |> Enum.member?({"x-amz-meta-height", "1080"})
        assert headers |> Enum.member?({"x-amz-meta-pages", "1"})
      end

      assert(
        FileSets.get_file_set!(file_set.id).derivatives["poster"] ==
          FileSets.poster_uri_for(file_set)
      )
    end

    test "poster cache invalidation", %{file_set: %{id: file_set_id}} do
      log =
        capture_log(fn ->
          assert {:ok, %{id: ^file_set_id}, %{}} =
                   send_test_message(GeneratePosterImage, %{file_set_id: file_set_id}, %{})
        end)

      assert log
             |> String.contains?(
               "Skipping cache invalidation for: /iiif/3/#{Secrets.prefix()}/posters/#{file_set_id}/*. No distribution id found."
             )
    end
  end

  describe "file set exists with a playlist uri and offset out of duration range" do
    setup do
      file_set =
        file_set_fixture(
          role: %{id: "A", scheme: "FILE_SET_ROLE"},
          extracted_metadata: @mediainfo,
          poster_offset: 90_000
        )

      ts = "/" <> Pairtree.generate!(file_set.id) <> "/test.ts"
      m3u8 = "/" <> Pairtree.generate!(file_set.id) <> "/test-1080.m3u8"
      adaptive = "/" <> Pairtree.generate!(file_set.id) <> "/test.m3u8"
      m3u8_uri = FileSets.streaming_uri_for(file_set.id) <> "test.m3u8"

      {:ok, file_set_with_playlist} =
        FileSets.update_file_set(file_set, %{derivatives: %{"playlist" => m3u8_uri}})

      upload_object(@streaming_bucket, m3u8, File.read!("test/fixtures/test-1080.m3u8"))
      upload_object(@streaming_bucket, adaptive, File.read!("test/fixtures/test.m3u8"))
      upload_object(@streaming_bucket, ts, File.read!("test/fixtures/test.ts"))

      on_exit(fn ->
        empty_bucket(@pyramid_bucket)
        empty_bucket(@streaming_bucket)
      end)

      {:ok, file_set: file_set_with_playlist}
    end

    test "process/2 with offset out of range", %{file_set: %{id: file_set_id} = file_set} do
      assert {:error, _, %{error: "Offset out of range"}} =
               send_test_message(GeneratePosterImage, %{file_set_id: file_set_id}, %{})

      assert(!object_exists?(FileSets.poster_uri_for(file_set)))

      assert is_nil(FileSets.get_file_set!(file_set.id).derivatives["poster"])
    end
  end

  describe "file set exists with no playlist and offset within duration range" do
    setup do
      file_set =
        file_set_fixture(
          role: %{id: "A", scheme: "FILE_SET_ROLE"},
          core_metadata: %{
            mime_type: "video/mov",
            location: "s3://#{@ingest_bucket}/small.m4v",
            original_filename: "small.m4v"
          },
          extracted_metadata: @mediainfo,
          derivatives: %{"playlist" => "s3://#{@streaming_bucket}/small.m4v"},
          poster_offset: 100
        )

      upload_object(@streaming_bucket, "small.m4v", File.read!("test/fixtures/small.m4v"))

      on_exit(fn ->
        empty_bucket(@pyramid_bucket)
        empty_bucket(@streaming_bucket)
      end)

      {:ok, file_set: file_set}
    end

    test "process/2", %{file_set: %{id: file_set_id} = file_set} do
      assert {:ok, %{id: ^file_set_id}, %{}} =
               send_test_message(GeneratePosterImage, %{file_set_id: file_set_id}, %{})

      assert(object_exists?(FileSets.poster_uri_for(file_set)))

      assert(
        FileSets.get_file_set!(file_set.id).derivatives["poster"] ==
          FileSets.poster_uri_for(file_set)
      )
    end
  end

  describe "file set exists with no playlist and offset outside of duration range" do
    setup do
      file_set =
        file_set_fixture(
          role: %{id: "A", scheme: "FILE_SET_ROLE"},
          core_metadata: %{
            mime_type: "video/mov",
            location: "s3://#{@ingest_bucket}/small.m4v",
            original_filename: "small.m4v"
          },
          extracted_metadata: @mediainfo,
          derivatives: %{"playlist" => "s3://#{@streaming_bucket}/small.m4v"},
          poster_offset: 2_000_000
        )

      upload_object(@streaming_bucket, "small.m4v", File.read!("test/fixtures/small.m4v"))

      on_exit(fn ->
        empty_bucket(@pyramid_bucket)
        empty_bucket(@streaming_bucket)
      end)

      {:ok, file_set: file_set}
    end

    test "process/2 with offset out of range", %{file_set: file_set} do
      assert {:error, _, %{error: "Offset 2000000 out of range for video duration 1000999.0"}} =
               send_test_message(GeneratePosterImage, %{file_set_id: file_set.id}, %{})

      assert(!object_exists?(FileSets.poster_uri_for(file_set)))
      assert is_nil(FileSets.get_file_set!(file_set.id).derivatives["poster"])
    end
  end
end
