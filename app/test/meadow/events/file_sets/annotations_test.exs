defmodule Meadow.Events.FileSets.AnnotationsTest do
  use Meadow.DataCase, async: false
  use Meadow.S3Case

  alias Meadow.Data.FileSets

  import Assertions
  import ExUnit.CaptureLog
  import Meadow.TestHelpers

  @moduletag walex: [Meadow.Events.FileSets.Annotations]
  describe "Meadow.Events.FileSets.Annotations" do
    setup do
      file_set = file_set_fixture()

      {:ok, %{id: id}} =
        FileSets.create_annotation(file_set, %{type: "transcription", status: "pending"})

      FileSets.update_annotation_content(id, "Some annotation content", language: ["en"])

      {:ok, annotation} =
        FileSets.get_annotation!(id)
        |> FileSets.update_annotation(%{status: "completed"})

      {:ok, %{annotation: annotation}}
    end

    test "deleting an annotation removes its S3 object", %{annotation: annotation} do
      assert object_exists?(annotation.s3_location) == true

      log =
        capture_log(fn ->
          {:ok, _} = FileSets.delete_annotation(annotation)

          assert_async(timeout: 2000) do
            assert object_exists?(annotation.s3_location) == false
          end
        end)

      assert log =~ "Deleting annotation S3 object"
    end
  end
end
