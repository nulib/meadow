defmodule Meadow.BucketNotificationTest do
  use Meadow.S3Case
  import Assertions

  @test_content "Test Content"
  @test_object "path/to/test-object"
  @md5 "d65cdbadce081581e7de64a5a44b4617"
  @sha1 "bebfefe6bd0a8175e99a83f217ed3d2dbfe55bc8"

  describe "notifications" do
    @tag s3: [%{bucket: "test-ingest", key: @test_object, content: @test_content}]
    test "object uploaded to ingest bucket gets checksum tagged" do
      assert_async(timeout: 2000, sleep_time: 150) do
        with %{body: %{tags: tags}} <-
               ExAws.S3.get_object_tagging("test-ingest", @test_object) |> ExAws.request!() do
          assert tags |> length() >= 4
          assert Enum.find(tags, &(&1.key == "computed-md5")) |> Map.get(:value) == @md5
          assert Enum.find(tags, &(&1.key == "computed-sha1")) |> Map.get(:value) == @sha1

          assert Enum.find(tags, &(&1.key == "computed-md5-last-modified"))
                 |> Map.get(:value)
                 |> String.match?(~r/^[0-9]+$/)

          assert Enum.find(tags, &(&1.key == "computed-sha1-last-modified"))
                 |> Map.get(:value)
                 |> String.match?(~r/^[0-9]+$/)
        end
      end
    end

    @tag s3: [%{bucket: "test-uploads", key: @test_object, content: @test_content}]
    test "object uploaded to uploads bucket gets checksum tagged" do
      assert_async(timeout: 2000, sleep_time: 150) do
        with %{body: %{tags: tags}} <-
               ExAws.S3.get_object_tagging("test-uploads", @test_object) |> ExAws.request!() do
          assert tags |> length() >= 4
          assert Enum.find(tags, &(&1.key == "computed-md5")) |> Map.get(:value) == @md5
          assert Enum.find(tags, &(&1.key == "computed-sha1")) |> Map.get(:value) == @sha1

          assert Enum.find(tags, &(&1.key == "computed-md5-last-modified"))
                 |> Map.get(:value)
                 |> String.match?(~r/^[0-9]+$/)

          assert Enum.find(tags, &(&1.key == "computed-sha1-last-modified"))
                 |> Map.get(:value)
                 |> String.match?(~r/^[0-9]+$/)
        end
      end
    end
  end
end
