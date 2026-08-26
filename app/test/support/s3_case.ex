defmodule Meadow.S3Case do
  @moduledoc """
  This module includes the setup, teardown, and utility functions
  for working with S3/Minio

  To have `S3Case` manage test fixtures in Minio, add an `s3` tag
  to the test containing a list of %{bucket, key, content} structs:

      defmodule Meadow.FileCheckerTest do
        use Meadow.BucketNames
        use Meadow.S3Case

        @bucket @ingest_bucket
        @key "file_checker_test/path/to/file.tif"
        @content "test/fixtures/file.tif"
        @fixture %{
          bucket: @bucket,
          key: @key,
          content: File.read!(@content)
        }

        @tag s3: [@fixture]
        test "file exists" do
          assert {:ok, _} = Meadow.AWS.S3.head_object(@bucket, @key)
        end
      end

  Note that the `key` is namespaced using the name of the test to avoid
  collisions with other test data. This is a good practice, especially
  if test are running `async`.

  Objects created using the tag will automatically be destroyed at the end
  of the test. Other resources (buckets and objects) created as by-products
  can be removed in the test's teardown code by using `delete_bucket/1`,
  `delete_object/2`, and `empty_bucket/1`, but be sure _only_ to delete
  resources created by that test to avoid stomping on another concurrent
  test's resources. The test suite will warn of any unmanaged resources left
  behind at the end of the run.
  """
  use ExUnit.CaseTemplate

  alias Meadow.AWS.S3

  using do
    quote do
      use Meadow.BucketNames

      alias Meadow.AWS.S3

      defp object_content(uri) do
        %{path: key, host: bucket} = URI.parse(uri)
        object_content(bucket, key)
      end

      defp object_content(bucket, key) do
        case S3.get_object(bucket, key) do
          {:ok, body} -> body
          _ -> nil
        end
      end

      defp object_exists?(uri) do
        %{path: key, host: bucket} = URI.parse(uri)
        object_exists?(bucket, key)
      end

      defp object_exists?(bucket, key), do: S3.object_exists?(bucket, key)

      # Atom keys are convenient in assertions and safe here, where the set of metadata
      # keys is bounded by the test suite itself.
      defp object_metadata(bucket, key) do
        case S3.head_object(bucket, key) do
          {:ok, %{metadata: metadata}} ->
            Map.new(metadata, fn {k, v} -> {String.to_atom(k), v} end)

          _ ->
            nil
        end
      end

      defp object_size(bucket, key) do
        case S3.head_object(bucket, key) do
          {:ok, %{content_length: content_length}} -> content_length
          _ -> 0
        end
      end

      defp delete_bucket(bucket) do
        bucket
        |> empty_bucket()
        |> S3.delete_bucket()
      end

      defp delete_object(uri) do
        %{path: key, host: bucket} = URI.parse(uri)
        delete_object(bucket, key)
      end

      defp delete_object(bucket, key), do: S3.delete_object(bucket, key)

      defp empty_bucket(bucket) do
        if S3.bucket_exists?(bucket) do
          bucket
          |> S3.stream_objects()
          |> Stream.map(& &1.key)
          |> then(&S3.delete_objects(bucket, &1))
        end

        bucket
      end

      defp upload_object(bucket, key, content) do
        S3.put_object!(bucket, key, to_string(content))
      end
    end
  end

  setup tags do
    tags
    |> Map.get(:s3, [])
    |> Enum.each(fn %{bucket: bucket, key: key, content: content} ->
      S3.put_object!(bucket, key, to_string(content))
    end)

    on_exit(fn ->
      tags
      |> Map.get(:s3, [])
      |> Enum.each(fn %{bucket: bucket, key: key} ->
        S3.delete_object!(bucket, key)
      end)
    end)

    :ok
  end

  def show_cleanup_warnings do
    require Logger

    all_buckets = S3.list_buckets!()

    with buckets <- Meadow.Config.buckets() do
      if Meadow.Config.use_localstack?() do
        (all_buckets -- buckets)
        |> Enum.each(&Logger.warning("Unexpected bucket left behind: #{&1}"))
      end

      buckets
      |> Enum.each(fn bucket ->
        bucket
        |> S3.stream_objects()
        |> Enum.each(&Logger.warning("Unexpected object left in bucket \"#{bucket}\": #{&1.key}"))
      end)
    end
  end
end
