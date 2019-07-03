defmodule Meadow.Ingest.BucketTest do
  use ExUnit.Case
  doctest Meadow.Ingest.Bucket

  import Mox

  setup :verify_on_exit!

  @project_folder_name "name-of-folder"

  describe "Ingest Bucket" do
    test ".create_project_folder writes an \"empty\" folder to the ingest bucket" do
      Meadow.ExAwsHttpMock
      |> expect(:request, 2, fn _method, _url, _body, _headers, _opts ->
        {:ok, %{status_code: 200}}
      end)

      assert Meadow.Ingest.Bucket.create_project_folder(@project_folder_name) ==
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

      assert Meadow.Ingest.Bucket.create_project_folder(@project_folder_name) ==
               {:ok, %{status_code: 200}}
    end
  end
end
