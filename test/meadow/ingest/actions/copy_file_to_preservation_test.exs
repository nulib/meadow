defmodule Meadow.Ingest.Actions.CopyFileToPreservationTest do
  use Meadow.DataCase
  alias Meadow.Data.FileSets
  alias Meadow.Ingest.Actions.CopyFileToPreservation
  alias Meadow.Utils.Pairtree
  import Mox

  @sha256 "3be2b0180066d23605f9f022ae68facecc7f11e557e88dea3219bb4d42e150b5"

  setup do
    file_set =
      file_set_fixture(%{
        accession_number: "123",
        role: "am",
        metadata: %{
          digests: %{
            "sha256" => @sha256
          },
          location: "s3://test-ingest/project-123/test.tif",
          original_filename: "test.tif"
        }
      })

    {:ok, file_set_id: file_set.id, pairtree: Pairtree.generate!(file_set.id, 4)}
  end

  describe "success" do
    test "process/2", %{file_set_id: file_set_id, pairtree: pairtree} do
      Meadow.ExAwsHttpMock
      |> stub(:request, fn :put, url, _body, headers, _opts ->
        src_path = headers |> List.keyfind("x-amz-copy-source", 0) |> elem(1)
        dest_path = URI.parse(url).path

        [_, dest_bucket, dest_key] = dest_path |> String.split("/", parts: 3)
        [_, src_bucket, src_key] = src_path |> String.split("/", parts: 3)

        send(self(), %{source: {src_bucket, src_key}, dest: {dest_bucket, dest_key}})
        {:ok, %{status_code: 200}}
      end)

      assert(CopyFileToPreservation.process(%{file_set_id: file_set_id}, %{}) == :ok)

      assert_received(%{
        source: source,
        dest: dest
      })

      assert source == {"test-ingest", "project-123/test.tif"}
      assert dest == {"test-preservation", "#{pairtree}/#{@sha256}"}
      file_set = FileSets.get_file_set!(file_set_id)
      assert(file_set.metadata.location =~ "/test-preservation/#{pairtree}/#{@sha256}")
    end
  end

  describe "failure" do
    test "process/2", %{file_set_id: file_set_id} do
      Meadow.ExAwsHttpMock
      |> stub(:request, fn :put, _url, _body, _headers, _opts ->
        {:ok, %{status_code: 404}}
      end)

      file_set = FileSets.get_file_set!(file_set_id)
      src_location = file_set.metadata.location
      assert({:error, _, _} = CopyFileToPreservation.process(%{file_set_id: file_set_id}, %{}))
      assert(FileSets.get_file_set!(file_set_id).metadata.location == src_location)
    end
  end
end
