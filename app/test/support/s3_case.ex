defmodule Meadow.S3Case do
  @moduledoc """
  This module includes the setup, teardown, and utility functions
  for working with S3/Minio

  To have `S3Case` manage test fixtures in Minio, add an `s3` tag
  to the test containing a list of %{bucket, key, content} structs:

      defmodule Meadow.FileCheckerTest do
        use Meadow.S3Case

        @bucket "test-ingest"
        @key "file_checker_test/path/to/file.tif"
        @content "test/fixtures/file.tif"
        @fixture %{
          bucket: @bucket,
          key: @key,
          content: File.read!(@content)
        }

        @tag s3: [@fixture]
        test "file exists" do
          assert {:ok, _} =
            ExAws.S3.head_object(@bucket, @key)
            |> ExAws.request!()
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

  using do
    quote do
      defp object_exists?(uri) do
        %{path: key, host: bucket} = URI.parse(uri)
        object_exists?(bucket, key)
      end

      defp object_exists?(bucket, key) do
        case bucket |> ExAws.S3.head_object(key) |> ExAws.request() do
          {:ok, _} -> true
          {:error, _} -> false
        end
      end

      defp object_metadata(bucket, key) do
        case bucket |> ExAws.S3.head_object(key) |> ExAws.request() do
          {:ok, %{headers: headers}} ->
            headers
            |> Enum.map(fn {header, value} -> {String.downcase(header), value} end)
            |> Enum.filter(fn {header, value} -> header |> String.starts_with?("x-amz-meta") end)
            |> Enum.map(fn {"x-amz-meta-" <> key, value} ->
              {key |> String.downcase() |> String.to_atom(), value}
            end)
            |> Enum.into(%{})

          _ ->
            nil
        end
      end

      defp object_size(bucket, key) do
        case bucket |> ExAws.S3.head_object(key) |> ExAws.request() do
          {:ok, %{headers: headers}} ->
            headers
            |> Enum.into(%{})
            |> Map.get("Content-Length")
            |> String.to_integer()

          _ ->
            0
        end
      end

      defp delete_bucket(bucket) do
        bucket
        |> empty_bucket()
        |> ExAws.S3.delete_bucket()
        |> ExAws.request()
      end

      defp delete_object(bucket, key) do
        ExAws.S3.delete_object(bucket, key)
        |> ExAws.request()
      end

      defp empty_bucket(bucket) do
        case ExAws.S3.head_bucket(bucket) |> ExAws.request() do
          {:ok, _} ->
            objects =
              bucket
              |> ExAws.S3.list_objects()
              |> ExAws.request!()
              |> get_in([:body, :contents])
              |> Enum.map(& &1.key)

            ExAws.S3.delete_all_objects(bucket, objects) |> ExAws.request()
            bucket

          {:error, _} ->
            bucket
        end
      end

      defp upload_object(bucket, key, content) do
        ExAws.S3.put_object(bucket, key, to_string(content))
        |> ExAws.request!()
      end
    end
  end

  setup tags do
    tags
    |> Map.get(:s3, [])
    |> Enum.each(fn %{bucket: bucket, key: key, content: content} ->
      ExAws.S3.put_object(bucket, key, to_string(content))
      |> ExAws.request!()
    end)

    on_exit(fn ->
      tags
      |> Map.get(:s3, [])
      |> Enum.each(fn %{bucket: bucket, key: key} ->
        ExAws.S3.delete_object(bucket, key) |> ExAws.request!()
      end)
    end)

    :ok
  end

  def add_tagging_header(op, content) do
    with digest <-
           :crypto.hash_init(:md5)
           |> :crypto.hash_update(content)
           |> :crypto.hash_final()
           |> Base.encode16()
           |> String.downcase(),
         tagging <- "computed-md5=#{digest}&computed-md5-last-modified=#{System.system_time()}",
         headers <- Map.get(op, :headers, %{}) do
      Map.put(op, :headers, Map.put(headers, "x-amz-tagging", tagging))
    end
  end

  def show_cleanup_warnings do
    require Logger

    all_buckets =
      ExAws.S3.list_buckets()
      |> ExAws.request!()
      |> get_in([:body, :buckets])
      |> Enum.map(& &1.name)

    with buckets <- Meadow.Config.buckets() do
      (all_buckets -- buckets)
      |> Enum.each(&Logger.warn("Unexpected bucket left behind: #{&1}"))

      buckets
      |> Enum.each(fn bucket ->
        objects =
          ExAws.S3.list_objects(bucket)
          |> ExAws.request!()
          |> get_in([:body, :contents])
          |> Enum.map(& &1.key)

        objects
        |> Enum.each(&Logger.warn("Unexpected object left in bucket \"#{bucket}\": #{&1}"))
      end)
    end
  end
end
