defmodule MeadowWeb.Schema.Subscription.FileSetAnnotationTest do
  use Meadow.DataCase, sandbox: false
  use MeadowWeb.SubscriptionCase, async: false

  alias Meadow.Data.FileSets

  @reply_timeout 5000

  load_gql(MeadowWeb.Schema, "test/gql/FileSetAnnotation.gql")

  @moduletag walex: [Meadow.Events.FileSets.Annotations]
  describe "FileSet annotation subscription" do
    setup %{socket: socket} do
      %{file_sets: [file_set | _]} = work_with_file_sets_fixture(1)

      {:ok, annotation} =
        FileSets.create_annotation(file_set, %{type: "transcription", status: "in_progress"})

      {:ok, s3_location} = FileSets.write_annotation_content(annotation, "Original content")
      {:ok, annotation} = FileSets.update_annotation(annotation, %{s3_location: s3_location})

      {:ok,
       %{
         annotation: annotation,
         file_set: file_set,
         ref:
           subscribe_gql(socket, variables: %{"fileSetId" => file_set.id, context: gql_context()})
       }}
    end

    test "receive annotation status updates", %{annotation: annotation, ref: ref} do
      assert_reply ref, :ok, %{subscriptionId: _subscription_id}, @reply_timeout
      annotation_id = annotation.id
      status = "completed"
      FileSets.update_annotation(annotation, %{status: status})

      assert_push "subscription:data", %{
        result: %{
          data: %{
            "fileSetAnnotation" => %{
              "id" => ^annotation_id,
              "status" => ^status
            }
          }
        }
      }
    end
  end
end
