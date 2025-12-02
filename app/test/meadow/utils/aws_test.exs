defmodule Meadow.Utils.AWSTest do
  use Honeybadger.Case
  use Meadow.S3Case
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
      assert {:ok, %{status_code: 200}} = AWS.create_s3_folder(@bucket, @project_folder_name)
    end

    # test "create_s3_folder/2 creates bucket when it does not exist" do
    #   with bucket <- @random_bucket do
    #     assert {:error, {:http_error, 404, _}} =
    #              bucket |> ExAws.S3.head_bucket() |> ExAws.request()
    #
    #     assert {:ok, %{status_code: 200}} = AWS.create_s3_folder(bucket, @project_folder_name)
    #   end
    # end
  end

  test "presigned_url/2 generates a presigned url" do
    config = ExAws.Config.new(:s3)
    scheme = config[:scheme]
    host = config[:host]
    port = config[:port]
    regex = ~r{#{scheme}#{host}(:#{port})?/#{@bucket}/ingest_sheets(.)*}

    with {:ok, presigned_url} <- AWS.presigned_url(@bucket, %{upload_type: "ingest_sheet"}) do
      assert presigned_url =~ regex
    end
  end

  test "presigned_url/2 for a file set uses the original filename's extension" do
    config = ExAws.Config.new(:s3)
    scheme = config[:scheme]
    host = config[:host]
    port = config[:port]
    regex = ~r{#{scheme}#{host}(:#{port})?/#{@bucket}/file_sets(.)*.jpg}

    with {:ok, presigned_url} <-
           AWS.presigned_url(@bucket, %{upload_type: "file_set", filename: "original.jpg"}) do
      assert presigned_url =~ regex
    end
  end
end
