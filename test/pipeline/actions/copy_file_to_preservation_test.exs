defmodule Meadow.Pipeline.Actions.CopyFileToPreservationTest do
  use Meadow.DataCase
  use Meadow.S3Case
  alias Meadow.Data.{ActionStates, FileSets}
  alias Meadow.Pipeline.Actions.CopyFileToPreservation
  alias Meadow.Utils.Pairtree
  import ExUnit.CaptureLog

  @md5 "85062e8c916f55ae0c514cb0732cfb1f"
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
        role: %{id: "A", scheme: "FILE_SET_ROLE"},
        core_metadata: %{
          digests: %{
            "md5" => @md5
          },
          location: "s3://#{@ingest_bucket}/#{@key}",
          mime_type: "image/tiff",
          original_filename: "test.tif"
        }
      })

    {:ok, file_set_id: file_set.id, preservation_key: Pairtree.preservation_path(file_set.id)}
  end

  describe "success" do
    @describetag s3: [@fixture]
    test "process/2", %{file_set_id: file_set_id, preservation_key: preservation_key} do
      assert(CopyFileToPreservation.process(%{file_set_id: file_set_id}, %{}) == :ok)
      assert(ActionStates.ok?(file_set_id, CopyFileToPreservation))

      file_set = FileSets.get_file_set!(file_set_id)

      assert(
        file_set.core_metadata.location =~ "s3://#{@preservation_bucket}/#{preservation_key}"
      )

      assert(object_exists?(@preservation_bucket, preservation_key))

      assert capture_log(fn ->
               CopyFileToPreservation.process(%{file_set_id: file_set_id}, %{})
             end) =~ "Skipping #{CopyFileToPreservation} for #{file_set_id} – already complete"

      with {:ok, %{headers: headers}} <-
             ExAws.S3.head_object(@preservation_bucket, preservation_key) |> ExAws.request() do
        assert headers |> Enum.member?({"Content-Type", "image/tiff"})
        assert headers |> Enum.member?({"x-amz-meta-md5", @md5})
      end

      with {:ok, %{body: %{tags: tags}}} <-
             ExAws.S3.get_object_tagging(@preservation_bucket, preservation_key)
             |> ExAws.request() do
        assert Enum.member?(tags, %{key: "computed-md5", value: @md5})
      end

      on_exit(fn ->
        delete_object(@preservation_bucket, preservation_key)
      end)
    end
  end

  describe "skip conditions" do
    @describetag s3: [@fixture]

    setup tags do
      ExAws.S3.put_object(@preservation_bucket, tags.preservation_key, @content)
      |> ExAws.request!()

      on_exit(fn ->
        delete_object(@preservation_bucket, tags.preservation_key)
      end)
    end

    test "file exists but metadata wrong", %{
      file_set_id: file_set_id,
      preservation_key: preservation_key
    } do
      log =
        capture_log(fn ->
          assert(
            %{file_set_id: file_set_id}
            |> CopyFileToPreservation.process(%{overwrite: "false"}) == :ok
          )

          assert(ActionStates.ok?(file_set_id, CopyFileToPreservation))
          assert(object_exists?(@preservation_bucket, preservation_key))
        end)

      refute log =~ ~r/already complete without overwriting/
    end
  end

  describe "overwrite flag" do
    @describetag s3: [@fixture]

    setup tags do
      ExAws.S3.put_object(@preservation_bucket, tags.preservation_key, @content)
      |> ExAws.request!()

      with file_set <- FileSets.get_file_set!(tags[:file_set_id]),
           preservation_url <- "s3://#{@preservation_bucket}/#{tags.preservation_key}" do
        FileSets.update_file_set(file_set, %{core_metadata: %{location: preservation_url}})
      end

      on_exit(fn ->
        delete_object(@preservation_bucket, tags.preservation_key)
      end)
    end

    test "overwrite", %{file_set_id: file_set_id, preservation_key: preservation_key} do
      log =
        capture_log(fn ->
          assert(CopyFileToPreservation.process(%{file_set_id: file_set_id}, %{}) == :ok)
          assert(ActionStates.ok?(file_set_id, CopyFileToPreservation))
          assert(object_exists?(@preservation_bucket, preservation_key))
        end)

      refute log =~ ~r/already complete without overwriting/
    end

    test "retain", %{file_set_id: file_set_id, preservation_key: preservation_key} do
      log =
        capture_log(fn ->
          assert(
            CopyFileToPreservation.process(%{file_set_id: file_set_id}, %{overwrite: "false"}) ==
              :ok
          )

          assert(ActionStates.ok?(file_set_id, CopyFileToPreservation))
          assert(object_exists?(@preservation_bucket, preservation_key))
        end)

      assert log =~ ~r/already complete without overwriting/
    end
  end
end
