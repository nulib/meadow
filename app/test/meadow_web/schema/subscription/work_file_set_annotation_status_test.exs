defmodule MeadowWeb.Schema.Subscription.WorkFileSetAnnotationTest do
  use Meadow.DataCase
  use MeadowWeb.SubscriptionCase, async: false

  alias Meadow.Data.FileSets

  @reply_timeout 5000

  load_gql(MeadowWeb.Schema, "test/gql/WorkFileSetAnnotation.gql")

  @moduletag walex: [Meadow.Events.FileSets.Annotations]
  describe "Work FileSet annotation status subscription" do
    setup %{socket: socket} do
      %{file_sets: file_sets} = work = work_with_file_sets_fixture(2)

      annotations =
        file_sets
        |> Enum.map(fn fs ->
          {:ok, annotation} =
            FileSets.create_annotation(fs, %{type: "transcription", status: "in_progress"})

          {:ok, s3_location} =
            FileSets.write_annotation_content(annotation, "Original content for " <> fs.id)

          {:ok, annotation} = FileSets.update_annotation(annotation, %{s3_location: s3_location})
          annotation
        end)

      {:ok,
       %{
         work: work,
         file_sets: file_sets,
         annotations: annotations,
         ref: subscribe_gql(socket, variables: %{"workId" => work.id, context: gql_context()})
       }}
    end

    test "receive annotation status updates", %{annotations: [a1, a2], ref: ref} do
      assert_reply ref, :ok, %{subscriptionId: _subscription_id}, @reply_timeout
      a1_id = a1.id
      a2_id = a2.id

      status = "completed"
      FileSets.update_annotation(a1, %{status: status})

      assert_push "subscription:data", %{
        result: %{
          data: %{
            "workFileSetAnnotation" => %{
              "id" => ^a1_id,
              "status" => ^status
            }
          }
        }
      }

      status = "error"
      FileSets.update_annotation(a2, %{status: status})

      assert_push "subscription:data", %{
        result: %{
          data: %{
            "workFileSetAnnotation" => %{
              "id" => ^a2_id,
              "status" => ^status
            }
          }
        }
      }
    end
  end
end
