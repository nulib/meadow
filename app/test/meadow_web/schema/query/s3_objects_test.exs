# defmodule MeadowWeb.Schema.Query.S3ObjectsTest do
#   use Meadow.DataCase
#   use Meadow.S3Case
#   use MeadowWeb.ConnCase, async: true

#   alias Meadow.Config
#   alias Meadow.Utils.AWS

#   import WaitForIt

#   @query """
#   query ($prefix: String) {
#     ListIngestBucketObjects(prefix: $prefix) {
#       objects {
#         uri
#         key
#         storageClass
#         size
#         lastModified
#         mimeType
#       }
#       folders
#     }
#   }
#   """

#   @image_fixture "test/fixtures/coffee.tif"
#   @json_fixture "test/fixtures/details.json"

#   setup do
#     file_fixtures = [
#       {@ingest_bucket, "coffee/coffee.tif", File.read!(@image_fixture)},
#       {@ingest_bucket, "details.json", File.read!(@json_fixture)}
#     ]

#     setup_fixtures(file_fixtures)

#     on_exit(fn -> cleanup_fixtures(file_fixtures) end)

#     {:ok, %{file_fixtures: file_fixtures}}
#   end

#   test "ListIngestBucketObjects query returns objects with a prefix", %{
#     file_fixtures: _file_fixtures
#   } do
#     conn = build_conn() |> auth_user(user_fixture())
#     variables = %{"prefix" => "coffee/"}

#     response =
#       conn
#       |> get("/api/graphql", query: @query, variables: variables)
#       |> json_response(200)

#     assert %{
#              "data" => %{
#                "ListIngestBucketObjects" => %{
#                  "objects" => [s3_object | []],
#                  "folders" => []
#                }
#              }
#            } = response

#     assert s3_object["uri"] == "s3://#{@ingest_bucket}/coffee/coffee.tif"
#     assert s3_object["key"] == "coffee/coffee.tif"
#     assert s3_object["mimeType"] == "application/octet-stream"
#     assert s3_object["size"] == "3179982"
#     assert s3_object["storageClass"] == "STANDARD"
#     assert_valid_iso8601_datetime(s3_object["lastModified"])
#   end

#   test "ListIngestBucketObjects query returns objects and folders" do
#     conn = build_conn() |> auth_user(user_fixture())

#     response =
#       conn
#       |> get("/api/graphql", query: @query)
#       |> json_response(200)

#     assert %{
#              "data" => %{
#                "ListIngestBucketObjects" => %{
#                  "objects" => [s3_object | []],
#                  "folders" => ["coffee"]
#                }
#              }
#            } = response

#     assert s3_object["uri"] == "s3://#{@ingest_bucket}/details.json"
#     assert s3_object["key"] == "details.json"
#     assert s3_object["mimeType"] == "application/octet-stream"
#     assert s3_object["size"] == "91"
#     assert s3_object["storageClass"] == "STANDARD"
#     assert_valid_iso8601_datetime(s3_object["lastModified"])
#   end

#   defp setup_fixtures(fixtures) do
#     fixtures
#     |> Task.async_stream(&upload_and_tag_fixture/1, timeout: Config.checksum_wait_timeout())
#     |> Stream.run()
#   end

#   defp upload_and_tag_fixture({bucket, key, content}) do
#     upload_object(bucket, key, content)

#     AWS.check_object_tags!(bucket, key, Config.required_checksum_tags())
#     |> wait(timeout: Config.checksum_wait_timeout(), frequency: 250)
#   end

#   defp cleanup_fixtures(fixtures) do
#     fixtures
#     |> Task.async_stream(fn {bucket, key, _} -> delete_object(bucket, key) end)
#     |> Stream.run()
#   end

#   defp assert_valid_iso8601_datetime(datetime_string) do
#     assert {:ok, _, 0} = DateTime.from_iso8601(datetime_string)
#   end
# end
