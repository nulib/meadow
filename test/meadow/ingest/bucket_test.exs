defmodule Meadow.Ingest.BucketTest do
  use Meadow.S3Case
  alias Meadow.Ingest.Bucket

  @project_folder_name "name-of-folder"
  @bucket "test-ingest"

  describe "Ingest Bucket" do
    setup do
      on_exit(fn ->
        empty_bucket(@bucket)
        delete_bucket("nonexistent-bucket")
      end)
    end

    test ".create_project_folder writes an \"empty\" folder to the ingest bucket" do
      assert {:ok, %{status_code: 200}} =
               Bucket.create_project_folder(@bucket, @project_folder_name)
    end

    test ".create_project_folder creates bucket when it does not exist" do
      with bucket <- "nonexistent-bucket" do
        assert {:error, {:http_error, 404, _}} =
                 bucket |> ExAws.S3.head_bucket() |> ExAws.request()

        assert {:ok, %{status_code: 200}} =
                 Bucket.create_project_folder(bucket, @project_folder_name)
      end
    end
  end

  test ".presigned_s3_url generates a presigned url" do
    config = ExAws.Config.new(:s3)
    scheme = config[:scheme]
    host = config[:host]
    port = config[:port]
    regex = ~r{#{scheme}#{host}:#{port}/#{@bucket}/ingest_sheets(.)*}

    assert Bucket.presigned_s3_url(@bucket) =~ regex
  end
end
