defmodule Meadow.Ingest.Projects.BucketTest do
  use ExUnit.Case
  alias Meadow.Ingest.Projects.Bucket

  import Mox

  setup :verify_on_exit!

  @project_folder_name "name-of-folder"
  @bucket 'bucket-name'

  describe "Ingest Bucket" do
    test ".create_project_folder writes an \"empty\" folder to the ingest bucket" do
      Meadow.ExAwsHttpMock
      |> expect(:request, 2, fn _method, _url, _body, _headers, _opts ->
        {:ok, %{status_code: 200}}
      end)

      assert Bucket.create_project_folder('bucket-name', @project_folder_name) ==
               {:ok, %{status_code: 200}}
    end

    test ".create_project_folder creates bucket when it does not exist" do
      Meadow.ExAwsHttpMock
      |> expect(:request, 1, fn :head, _url, _body, _headers, _opts ->
        {:ok, %{status_code: 404}}
      end)
      |> expect(:request, 2, fn :put, _url, _body, _headers, _opts ->
        {:ok, %{status_code: 200}}
      end)

      assert Bucket.create_project_folder('bucket-name', @project_folder_name) ==
               {:ok, %{status_code: 200}}
    end
  end

  test ".presigned_s3_url generates a presigned url" do
    Meadow.ExAwsHttpMock
    |> expect(:request, 1, fn :head, _url, _body, _headers, _opts ->
      {:ok, %{status_code: 200}}
    end)

    config = ExAws.Config.new(:s3)
    scheme = config[:scheme]
    host = config[:host]
    port = config[:port]
    regex = ~r{#{scheme}#{host}:#{port}/#{@bucket}/ingest_sheets(.)*}

    assert Bucket.presigned_s3_url(@bucket) =~ regex
  end
end
