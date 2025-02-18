# defmodule Meadow.BucketNotificationTest do
#   use Meadow.S3Case
#   import Assertions

#   @test_content "Test Content"
#   @test_object "path/to/test-object"
#   @md5 "d65cdbadce081581e7de64a5a44b4617"

#   describe "notifications" do
#     @tag s3: [%{bucket: @ingest_bucket, key: @test_object, content: @test_content}]
#     test "object uploaded to ingest bucket gets checksum tagged" do
#       assert_async(timeout: 10_000, sleep_time: 500) do
#         with %{body: %{tags: tags}} <-
#                ExAws.S3.get_object_tagging(@ingest_bucket, @test_object) |> ExAws.request!() do
#           assert tags |> length() >= 2
#           assert Enum.find(tags, &(&1.key == "computed-md5")) |> Map.get(:value) == @md5

#           assert Enum.find(tags, &(&1.key == "computed-md5-last-modified"))
#                  |> Map.get(:value)
#                  |> String.match?(~r/^[0-9]+$/)
#         end
#       end
#     end

#     @tag s3: [%{bucket: @upload_bucket, key: @test_object, content: @test_content}]
#     test "object uploaded to uploads bucket gets checksum tagged" do
#       assert_async(timeout: 10_000, sleep_time: 500) do
#         with %{body: %{tags: tags}} <-
#                ExAws.S3.get_object_tagging(@upload_bucket, @test_object) |> ExAws.request!() do
#           assert tags |> length() >= 2
#           assert Enum.find(tags, &(&1.key == "computed-md5")) |> Map.get(:value) == @md5

#           assert Enum.find(tags, &(&1.key == "computed-md5-last-modified"))
#                  |> Map.get(:value)
#                  |> String.match?(~r/^[0-9]+$/)
#         end
#       end
#     end
#   end
# end
