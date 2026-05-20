defmodule Meadow.Events.FileSets.AnnotationsTest do
  use Meadow.DataCase, async: false
  use Meadow.S3Case

  alias Meadow.Data.FileSets

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

    test "deleting an annotation removes it from the database", %{annotation: annotation} do
      annotation_id = annotation.id
      assert {:ok, _} = FileSets.delete_annotation(annotation)
      assert_raise Ecto.NoResultsError, fn -> FileSets.get_annotation!(annotation_id) end
    end
  end
end
