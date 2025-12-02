defmodule MeadowWeb.Schema.Mutation.UpdateFileSetAnnotationTest do
  use Meadow.DataCase
  use Meadow.S3Case
  use MeadowWeb.ConnCase, async: true
  use Wormwood.GQLCase

  alias Meadow.Data.FileSets

  load_gql(MeadowWeb.Schema, "test/gql/UpdateFileSetAnnotation.gql")

  setup do
    file_set = file_set_fixture()
    {:ok, annotation} = FileSets.create_annotation(file_set, %{type: "transcription", status: "completed"})
    {:ok, s3_location} = FileSets.write_annotation_content(annotation, "Original content")
    {:ok, annotation} = FileSets.update_annotation(annotation, %{s3_location: s3_location})

    {:ok, annotation: annotation}
  end

  test "updates annotation content", %{annotation: annotation} do
    result =
      query_gql(
        variables: %{
          "annotationId" => annotation.id,
          "content" => "Updated content"
        },
        context: gql_context()
      )

    assert {:ok, query_data} = result
    content = get_in(query_data, [:data, "updateFileSetAnnotation", "content"])
    assert content == "Updated content"
  end

  test "updates annotation language", %{annotation: annotation} do
    result =
      query_gql(
        variables: %{
          "annotationId" => annotation.id,
          "content" => "Updated content",
          "language" => ["lg", "en"]
        },
        context: gql_context()
      )

    assert {:ok, query_data} = result
    language = get_in(query_data, [:data, "updateFileSetAnnotation", "language"])
    assert language == ["lg", "en"]
  end
end
