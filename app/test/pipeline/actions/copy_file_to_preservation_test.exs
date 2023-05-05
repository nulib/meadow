defmodule Meadow.Pipeline.Actions.CopyFileToPreservationTest do
  use Meadow.S3Case
  use Meadow.DataCase
  use Meadow.PipelineCase

  alias Meadow.Data.{ActionStates, FileSets}
  alias Meadow.Pipeline.Actions.CopyFileToPreservation
  alias Meadow.Utils.Pairtree

  import ExUnit.CaptureLog

  @md5 "85062e8c916f55ae0c514cb0732cfb1f"
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
      assert(
        {:ok, %{id: ^file_set_id}, %{}} =
          send_test_message(CopyFileToPreservation, %{file_set_id: file_set_id}, %{})
      )

      assert(ActionStates.ok?(file_set_id, CopyFileToPreservation))

      file_set = FileSets.get_file_set!(file_set_id)

      assert file_set.core_metadata.location =~ "s3://#{@preservation_bucket}/#{preservation_key}"

      assert(object_exists?(@preservation_bucket, preservation_key))

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
            {:ok, %{id: ^file_set_id}, %{}} =
              send_test_message(CopyFileToPreservation, %{file_set_id: file_set_id}, %{
                overwrite: "false"
              })
          )

          assert(ActionStates.ok?(file_set_id, CopyFileToPreservation))
          assert(object_exists?(@preservation_bucket, preservation_key))
        end)

      refute log =~ ~r/already complete without overwriting/
    end
  end

  describe "force flag" do
    @describetag s3: [@fixture]

    setup %{file_set_id: file_set_id, preservation_key: preservation_key} do
      send_test_message(CopyFileToPreservation, %{file_set_id: file_set_id}, %{})

      on_exit(fn ->
        delete_object(@preservation_bucket, preservation_key)
      end)

      :ok
    end

    test "skip if not forced", %{file_set_id: file_set_id} do
      assert(ActionStates.ok?(file_set_id, CopyFileToPreservation))

      assert capture_log(fn ->
               send_test_message(CopyFileToPreservation, %{file_set_id: file_set_id}, %{})
             end) =~ "Skipping #{CopyFileToPreservation} for #{file_set_id} - already complete"
    end

    test "re-run if forced", %{file_set_id: file_set_id} do
      assert(ActionStates.ok?(file_set_id, CopyFileToPreservation))

      assert capture_log(fn ->
               send_test_message(CopyFileToPreservation, %{file_set_id: file_set_id}, %{
                 force: "true"
               })
             end) =~
               "Forcing #{CopyFileToPreservation} for #{file_set_id} even though it's already complete"
    end
  end

  describe "overwrite flag" do
    @describetag s3: [@fixture]

    setup tags do
      ExAws.S3.put_object(@preservation_bucket, tags.preservation_key, @content)
      |> ExAws.request!()

      ExAws.S3.put_object(@ingest_bucket, "ingest-object", @content)
      |> ExAws.request!()

      on_exit(fn ->
        delete_object(@preservation_bucket, tags.preservation_key)
        delete_object(@ingest_bucket, "ingest-object")
      end)
    end

    test "overwrite", %{file_set_id: file_set_id, preservation_key: preservation_key} do
      with file_set <- FileSets.get_file_set!(file_set_id),
           ingest_url <- "s3://#{@ingest_bucket}/ingest-object" do
        FileSets.update_file_set(file_set, %{core_metadata: %{location: ingest_url}})
      end

      log =
        capture_log(fn ->
          assert(
            {:ok, %{id: ^file_set_id}, %{}} =
              send_test_message(CopyFileToPreservation, %{file_set_id: file_set_id}, %{})
          )

          assert(ActionStates.ok?(file_set_id, CopyFileToPreservation))
          assert(object_exists?(@preservation_bucket, preservation_key))
        end)

      refute log =~ ~r/already complete without overwriting/
    end

    test "retain", %{file_set_id: file_set_id, preservation_key: preservation_key} do
      with file_set <- FileSets.get_file_set!(file_set_id),
           preservation_url <- "s3://#{@preservation_bucket}/#{preservation_key}" do
        FileSets.update_file_set(file_set, %{core_metadata: %{location: preservation_url}})
      end

      log =
        capture_log(fn ->
          assert {:ok, %{id: ^file_set_id}, %{}} =
                   send_test_message(CopyFileToPreservation, %{file_set_id: file_set_id}, %{
                     overwrite: "false"
                   })

          assert(ActionStates.ok?(file_set_id, CopyFileToPreservation))
          assert(object_exists?(@preservation_bucket, preservation_key))
        end)

      assert log =~ ~r/already complete without overwriting/
    end
  end
end
