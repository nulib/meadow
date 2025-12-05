defmodule MeadowWeb.Schema.Mutation.DeleteFileSetAnnotationTest do
  use Meadow.DataCase
  use Meadow.S3Case
  use MeadowWeb.ConnCase, async: true
  use Wormwood.GQLCase

  alias Meadow.Data.FileSets

  load_gql(MeadowWeb.Schema, "test/gql/DeleteFileSetAnnotation.gql")

  setup do
    file_set = file_set_fixture()
    {:ok, annotation} = FileSets.create_annotation(file_set, %{type: "transcription", status: "completed"})
    {:ok, s3_location} = FileSets.write_annotation_content(annotation, "Original content")
    {:ok, annotation} = FileSets.update_annotation(annotation, %{s3_location: s3_location})

    {:ok, annotation: annotation, file_set: file_set}
  end

  test "deletes annotation", %{annotation: annotation, file_set: file_set} do
    result =
      query_gql(
        variables: %{
          "annotationId" => annotation.id
        },
        context: gql_context()
      )

    assert {:ok, query_data} = result
    deleted_id = get_in(query_data, [:data, "deleteFileSetAnnotation", "id"])
    assert deleted_id == annotation.id

    # Verify annotation is actually deleted
    assert [] = FileSets.list_annotations(file_set)
  end

  test "returns error for non-existent annotation" do
    result =
      query_gql(
        variables: %{
          "annotationId" => "00000000-0000-0000-0000-000000000000"
        },
        context: gql_context()
      )

    assert {:ok, query_data} = result
    assert [%{message: "Annotation not found"}] = query_data[:errors]
  end
end
