defmodule Meadow.Utils.AWSTest do
  use Honeybadger.Case
  use Meadow.S3Case

  alias Meadow.AWS.S3
  alias Meadow.Utils.AWS

  @project_folder_name "name-of-folder"
  @bucket @ingest_bucket
  @random_bucket "nonexistent-#{DateTime.utc_now() |> DateTime.to_unix()}"

  describe "log_metrics/1" do
    test "log_metrics/1 sends a log to CloudWatch Logs" do
      message = %{"test_key" => "test_value"}
      assert {:ok, _response} = AWS.log_metrics(message)
    end
  end

  describe "create_s3_folder/2" do
    setup do
      on_exit(fn ->
        empty_bucket(@bucket)
        delete_bucket(@random_bucket)
      end)
    end

    test "create_s3_folder/2 writes an \"empty\" folder to a bucket" do
      assert :ok = AWS.create_s3_folder(@bucket, @project_folder_name)
    end

    test "create_s3_folder/2 creates the bucket when it does not exist" do
      with bucket <- @random_bucket do
        refute S3.bucket_exists?(bucket)
        assert :ok = AWS.create_s3_folder(bucket, @project_folder_name)
        assert S3.bucket_exists?(bucket)
      end
    end
  end

  test "presigned_url/2 generates a presigned url" do
    regex = ~r{#{endpoint()}/#{@bucket}/ingest_sheets(.)*}

    with {:ok, presigned_url} <- AWS.presigned_url(@bucket, %{upload_type: "ingest_sheet"}) do
      assert presigned_url =~ regex
    end
  end

  test "presigned_url/2 for a file set uses the original filename's extension" do
    regex = ~r{#{endpoint()}/#{@bucket}/file_sets(.)*.jpg}

    with {:ok, presigned_url} <-
           AWS.presigned_url(@bucket, %{upload_type: "file_set", filename: "original.jpg"}) do
      assert presigned_url =~ regex
    end
  end

  # The scheme/host/port `Meadow.AWS` will actually sign against, escaped for a regex.
  defp endpoint do
    client = Meadow.AWS.client(:s3)

    client
    |> Meadow.AWS.endpoint_url(Meadow.AWS.host(client, "s3"))
    |> Regex.escape()
  end
end
