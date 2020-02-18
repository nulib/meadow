defmodule Meadow.Pipeline.Actions.CopyFileToPreservationTest do
  use Meadow.DataCase
  use Meadow.S3Case
  alias Meadow.Data.{ActionStates, FileSets}
  alias Meadow.Pipeline.Actions.CopyFileToPreservation
  alias Meadow.Utils.Pairtree
  import ExUnit.CaptureLog

  @sha256 "412ca147684a67883226c644ee46b38460b787ec34e5b240983992af4a8c0a90"
  @ingest_bucket Meadow.Config.ingest_bucket()
  @preservation_bucket Meadow.Config.preservation_bucket()
  @key "copy_file_to_preservation_test/test.tif"
  @content "test/fixtures/coffee.tif"
  @fixture %{bucket: @ingest_bucket, key: @key, content: File.read!(@content)}
  @id "7aab17f1-89b4-4716-8421-e2f3f4c161ec"

  setup do
    file_set =
      file_set_fixture(%{
        id: @id,
        accession_number: "123",
        role: "am",
        metadata: %{
          digests: %{
            "sha256" => @sha256
          },
          location: "s3://#{@ingest_bucket}/#{@key}",
          original_filename: "test.tif"
        }
      })

    {:ok,
     file_set_id: file_set.id,
     preservation_key:
       Pairtree.preservation_path(
         file_set.id,
         Map.get(file_set.metadata.digests, "sha256")
       )}
  end

  @tag s3: [@fixture]
  describe "success" do
    test "process/2", %{file_set_id: file_set_id, preservation_key: preservation_key} do
      assert(CopyFileToPreservation.process(%{file_set_id: file_set_id}, %{}) == :ok)
      assert(ActionStates.ok?(file_set_id, CopyFileToPreservation))

      file_set = FileSets.get_file_set!(file_set_id)

      assert(file_set.metadata.location =~ "s3://#{@preservation_bucket}/#{preservation_key}")

      assert(object_exists?(@preservation_bucket, preservation_key))

      assert capture_log(fn ->
               CopyFileToPreservation.process(%{file_set_id: file_set_id}, %{})
             end) =~ "Skipping #{CopyFileToPreservation} for #{file_set_id} – already complete"

      on_exit(fn ->
        delete_object(@preservation_bucket, preservation_key)
      end)
    end
  end
end
