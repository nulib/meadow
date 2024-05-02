defmodule Meadow.Pipeline.Actions.CreateDerivativeCopyTest do
  use Meadow.S3Case
  use Meadow.DataCase
  use Meadow.PipelineCase

  alias Meadow.Data.{ActionStates, FileSets}
  alias Meadow.Pipeline.Actions.CreateDerivativeCopy
  alias Meadow.Utils.Pairtree

  import ExUnit.CaptureLog

  @md5 "85062e8c916f55ae0c514cb0732cfb1f"
  @key "copy_file_to_preservation_test/test.tif"
  @content "test/fixtures/test.pdf"
  @fixture %{bucket: @ingest_bucket, key: @key, content: File.read!(@content)}
  @id "7aab17f1-89b4-4716-8421-e2f3f4c161ec"

  setup do
    file_set =
      file_set_fixture(%{
        id: @id,
        accession_number: "123",
        role: %{id: "X", scheme: "FILE_SET_ROLE"},
        core_metadata: %{
          digests: %{
            "md5" => @md5
          },
          location: "s3://#{@ingest_bucket}/#{@key}",
          mime_type: "application.pdf",
          original_filename: "test.pdf"
        }
      })

    {:ok,
     file_set_id: file_set.id,
     derivative_key: "derivatives/#{Pairtree.derivative_path(file_set.id)}"}
  end

  describe "success" do
    @describetag s3: [@fixture]
    test "process/2", %{file_set_id: file_set_id} do
      assert(
        {:ok, %{id: ^file_set_id}, %{}} =
          send_test_message(CreateDerivativeCopy, %{file_set_id: file_set_id}, %{})
      )

      assert(ActionStates.ok?(file_set_id, CreateDerivativeCopy))

      file_set = FileSets.get_file_set!(file_set_id)
      dest_key = FileSets.derivative_key(file_set)

      assert FileSets.get_file_set(file_set_id)
             |> Map.get(:derivatives)
             |> Map.get("copy") == "s3://#{@pyramid_bucket}/#{dest_key}"

      assert(object_exists?(@pyramid_bucket, dest_key))

      on_exit(fn ->
        delete_object(@pyramid_bucket, dest_key)
      end)
    end
  end

  describe "skip conditions" do
    @describetag s3: [@fixture]

    setup tags do
      ExAws.S3.put_object(@pyramid_bucket, tags.derivative_key, @content)
      |> ExAws.request!()

      on_exit(fn ->
        delete_object(@preservation_bucket, tags.derivative_key)
      end)
    end

    test "derivative file exists", %{
      file_set_id: file_set_id
    } do
      file_set = FileSets.get_file_set!(file_set_id)
      dest_key = FileSets.derivative_key(file_set)

      log =
        capture_log(fn ->
          assert(
            {:ok, %{id: ^file_set_id}, %{}} =
              send_test_message(CreateDerivativeCopy, %{file_set_id: file_set_id}, %{})
          )

          assert(ActionStates.ok?(file_set_id, CreateDerivativeCopy))
          assert(object_exists?(@pyramid_bucket, dest_key))
        end)

      refute log =~ ~r/foo/
    end
  end
end
