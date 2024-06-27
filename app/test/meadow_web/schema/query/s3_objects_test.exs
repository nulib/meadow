defmodule MeadowWeb.Schema.Query.S3ObjectsTest do
  use Meadow.DataCase
  use Meadow.S3Case
  use MeadowWeb.ConnCase, async: true

  alias Meadow.Config
  alias Meadow.Utils.AWS

  import WaitForIt

  @query """
  query ($prefix: String) {
    ListIngestBucketObjects(prefix: $prefix) {
      key
      storageClass
      size
      lastModified
      mimeType
    }
  }
  """

  @image_fixture "test/fixtures/coffee.tif"
  @json_fixture "test/fixtures/details.json"

  setup do
    file_fixtures = [
      {@ingest_bucket, "coffee/coffee.tif", File.read!(@image_fixture)},
      {@ingest_bucket, "details.json", File.read!(@json_fixture)}
    ]

    setup_fixtures(file_fixtures)

    on_exit(fn -> cleanup_fixtures(file_fixtures) end)

    {:ok, %{file_fixtures: file_fixtures}}
  end

  test "ListIngestBucketObjects query returns objects with a prefix", %{
    file_fixtures: _file_fixtures
  } do
    conn = build_conn() |> auth_user(user_fixture())
    variables = %{"prefix" => "coffee"}

    response =
      conn
      |> get("/api/graphql", query: @query, variables: variables)
      |> json_response(200)

    assert %{
             "data" => %{
               "ListIngestBucketObjects" => [s3_object]
             }
           } = response

    assert s3_object["key"] == "s3://#{@ingest_bucket}/coffee/coffee.tif"
    assert s3_object["mimeType"] == "application/octet-stream"
    assert s3_object["size"] == "3179982"
    assert s3_object["storageClass"] == "STANDARD"
    assert_valid_iso8601_datetime(s3_object["lastModified"])

    refute Enum.any?(
             response["data"]["ListIngestBucketObjects"],
             &(&1["key"] == "s3://#{@ingest_bucket}/details.json")
           )
  end

  test "ListIngestBucketObjects query returns all objects in the ingest bucket", %{
    file_fixtures: file_fixtures
  } do
    conn = build_conn() |> auth_user(user_fixture())

    response =
      conn
      |> get("/api/graphql", query: @query)
      |> json_response(200)

    s3_objects = response["data"]["ListIngestBucketObjects"]

    assert Enum.all?(file_fixtures, fn {bucket, key, _} ->
             expected_key = "s3://#{bucket}/#{key}"
             Enum.any?(s3_objects, &(&1["key"] == expected_key))
           end)
  end

  defp setup_fixtures(fixtures) do
    fixtures
    |> Task.async_stream(&upload_and_tag_fixture/1, timeout: Config.checksum_wait_timeout())
    |> Stream.run()
  end

  defp upload_and_tag_fixture({bucket, key, content}) do
    upload_object(bucket, key, content)

    AWS.check_object_tags!(bucket, key, Config.required_checksum_tags())
    |> wait(timeout: Config.checksum_wait_timeout(), frequency: 250)
  end

  defp cleanup_fixtures(fixtures) do
    fixtures
    |> Task.async_stream(fn {bucket, key, _} -> delete_object(bucket, key) end)
    |> Stream.run()
  end

  defp assert_valid_iso8601_datetime(datetime_string) do
    assert {:ok, _, 0} = DateTime.from_iso8601(datetime_string)
  end
end
