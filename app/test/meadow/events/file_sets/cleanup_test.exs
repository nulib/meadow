defmodule Meadow.Events.FileSets.CleanupTest do
  use Meadow.DataCase, async: false
  use Meadow.S3Case
  use Meadow.BucketNames

  alias Meadow.Data.{FileSets, Works}

  import Assertions
  import ExUnit.CaptureLog
  import Meadow.TestHelpers

  @fixtures [
    %{
      bucket: @streaming_bucket,
      key: "file_sets/cleanup_test/streaming/playlist.m3u8",
      content: "test/fixtures/test.m3u8"
    },
    %{
      bucket: @pyramid_bucket,
      key: "file_sets/cleanup_test/pyramid_file",
      content: "test/fixtures/coffee.tif"
    },
    %{
      bucket: @pyramid_bucket,
      key: "file_sets/cleanup_test/poster_file",
      content: "test/fixtures/coffee.tif"
    }
  ]

  @ingest_fixture %{
    bucket: @ingest_bucket,
    key: "file_sets/cleanup_test/ingest_file",
    content: "test/fixtures/coffee.tif"
  }

  @preservation_fixture %{
    bucket: @preservation_bucket,
    key: "file_sets/cleanup_test/preservation_file",
    content: "test/fixtures/coffee.tif"
  }

  @moduletag walex: [Meadow.Events.FileSets.Cleanup]
  describe "Meadow.Events.FileSets.Cleanup" do
    setup do
      work = work_fixture()

      file_set =
        file_set_fixture(%{
          work_id: work.id,
          derivatives: %{
            playlist: "s3://#{@streaming_bucket}/file_sets/cleanup_test/streaming/playlist.m3u8",
            pyramid: "s3://#{@pyramid_bucket}/file_sets/cleanup_test/pyramid_file",
            poster: "s3://#{@pyramid_bucket}/file_sets/cleanup_test/poster_file"
          },
          core_metadata: %{
            location: "s3://#{@preservation_bucket}/file_sets/cleanup_test/preservation_file",
            original_filename: "coffee.tif"
          }
        })

      structural_metadata = %{
        bucket: @pyramid_bucket,
        key: FileSets.vtt_location(file_set.id),
        content: "test/fixtures/Donohue_002_01.vtt"
      }

      upload_object(
        structural_metadata[:bucket],
        structural_metadata[:key],
        structural_metadata[:content]
      )

      {:ok, work: work, file_set: file_set, fixtures: [structural_metadata | @fixtures]}
    end

    @tag s3: [@preservation_fixture | @fixtures]
    test "deletes all relevant files", %{work: work, file_set: file_set, fixtures: fixtures} do
      fixtures
      |> Enum.each(fn fixture ->
        assert object_exists?(fixture[:bucket], fixture[:key])
      end)

      log =
        capture_log(fn ->
          Works.delete_work(work)

          assert_async(timeout: 2000) do
            fixtures
            |> Enum.each(fn fixture ->
              refute object_exists?(fixture[:bucket], fixture[:key])
            end)
          end
        end)

      [
        "Cleaning up assets for file set #{file_set.id}",
        "Removing playlist derivative",
        "Removing pyramid derivative",
        "Removing poster derivative",
        "Removing preservation file",
        "Removing structural metadata"
      ]
      |> Enum.each(fn message ->
        assert String.contains?(log, message)
      end)
    end

    @tag s3: [@ingest_fixture | @fixtures]
    test "leaves ingest files intact", %{work: work, file_set: file_set, fixtures: fixtures} do
      location = "s3://#{@ingest_fixture[:bucket]}/#{@ingest_fixture[:key]}"

      {:ok, file_set} =
        FileSets.update_file_set(file_set, %{core_metadata: %{location: location}})

      fixtures
      |> Enum.each(fn fixture ->
        assert object_exists?(fixture[:bucket], fixture[:key])
      end)

      log =
        capture_log(fn ->
          Works.delete_work(work)

          assert_async(timeout: 2000) do
            fixtures
            |> Enum.each(fn fixture ->
              refute object_exists?(fixture[:bucket], fixture[:key])
            end)

            assert object_exists?(@ingest_fixture[:bucket], @ingest_fixture[:key])
          end
        end)

      refute String.contains?(log, "Removing preservation file")

      [
        "Cleaning up assets for file set #{file_set.id}",
        "Removing playlist derivative",
        "Removing pyramid derivative",
        "Removing poster derivative",
        "Removing structural metadata",
        "Leaving #{location} intact in the ingest bucket"
      ]
      |> Enum.each(fn message ->
        assert String.contains?(log, message)
      end)
    end
  end
end
