defmodule Meadow.Utils.AWSTest do
  use Honeybadger.Case
  use Meadow.S3Case
  alias Meadow.Config
  alias Meadow.Utils.AWS

  @project_folder_name "name-of-folder"
  @bucket "test-ingest"

  describe "create_s3_folder/2" do
    setup do
      on_exit(fn ->
        empty_bucket(@bucket)
        delete_bucket("nonexistent-bucket")
      end)
    end

    test "create_s3_folder/2 writes an \"empty\" folder to a bucket" do
      assert {:ok, %{status_code: 200}} = AWS.create_s3_folder(@bucket, @project_folder_name)
    end

    test "create_s3_folder/2 creates bucket when it does not exist" do
      with bucket <- "nonexistent-bucket" do
        assert {:error, {:http_error, 404, _}} =
                 bucket |> ExAws.S3.head_bucket() |> ExAws.request()

        assert {:ok, %{status_code: 200}} = AWS.create_s3_folder(bucket, @project_folder_name)
      end
    end
  end

  test "presigned_url/2 generates a presigned url" do
    config = ExAws.Config.new(:s3)
    scheme = config[:scheme]
    host = config[:host]
    port = config[:port]
    regex = ~r{#{scheme}#{host}:#{port}/#{@bucket}/ingest_sheets(.)*}

    with {:ok, presigned_url} <- AWS.presigned_url(@bucket, %{upload_type: "ingest_sheet"}) do
      assert presigned_url =~ regex
    end
  end

  test "presigned_url/2 for a file set uses the original filename's extension" do
    config = ExAws.Config.new(:s3)
    scheme = config[:scheme]
    host = config[:host]
    port = config[:port]
    regex = ~r{#{scheme}#{host}:#{port}/#{@bucket}/file_sets(.)*.jpg}

    with {:ok, presigned_url} <-
           AWS.presigned_url(@bucket, %{upload_type: "file_set", filename: "original.jpg"}) do
      assert presigned_url =~ regex
    end
  end

  describe "error handling" do
    setup do
      {:ok, _} = Honeybadger.API.start(self())
      restart_with_config(exclude_envs: [])

      on_exit(&Honeybadger.API.stop/0)
    end

    test "request/2 does not report to Honeybadger when request is successful" do
      ExAws.S3.head_bucket(Config.upload_bucket())
      |> AWS.request()

      refute_receive {:api_request, _report}, 1000
    end

    test "request/2 reports error when AWS returns an HTTP error with a body" do
      ExAws.S3.put_object("nonexistent-bucket", "/path/to/key", "contents")
      |> AWS.request()

      assert_receive {:api_request, report}, 1000

      assert report |> get_in(["error", "class"]) == "Meadow.AwsError"

      assert report |> get_in(["error", "message"]) ==
               "404 (NoSuchBucket): The specified bucket does not exist"

      assert report |> get_in(["request", "context", "BucketName"]) == "nonexistent-bucket"
    end

    test "request/2 reports error when AWS returns an HTTP error without a body" do
      ExAws.S3.head_bucket("nonexistent-bucket")
      |> AWS.request()

      assert_receive {:api_request, report}, 1000

      assert report |> get_in(["error", "class"]) == "Meadow.AwsError"
      assert report |> get_in(["error", "message"]) == "404"
    end

    test "request/2 reports error when ExAws fails any other way" do
      {:error, "Catastrophic Failure"}
      |> AWS.handle_response()

      assert_receive {:api_request, report}, 1000

      assert report |> get_in(["error", "class"]) == "Meadow.AwsError"
      assert report |> get_in(["error", "message"]) == "Catastrophic Failure"
    end

    test "request!/2 does not raise or report when AWS request is successful" do
      ExAws.S3.head_bucket(Config.upload_bucket())
      |> AWS.request!()

      refute_receive {:api_request, _report}, 1000
    end

    test "request!/2 reports and raises when it encounters an error" do
      assert_raise(ExAws.Error, fn ->
        ExAws.S3.put_object("nonexistent-bucket", "/path/to/key", "contents")
        |> AWS.request!()
      end)

      assert_receive {:api_request, report}, 1000

      assert report |> get_in(["error", "message"]) ==
               "404 (NoSuchBucket): The specified bucket does not exist"

      assert report |> get_in(["request", "context", "BucketName"]) == "nonexistent-bucket"
    end
  end
end
