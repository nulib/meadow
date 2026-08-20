defmodule MeadowWeb.Schema.Subscription.FileSetAnnotationTest do
  use Meadow.DataCase, sandbox: false
  use MeadowWeb.SubscriptionCase, async: false

  alias Meadow.Data.FileSets
  alias Meadow.Data.Schemas.FileSetAnnotation

  import Assertions
  import Mox

  @reply_timeout 5000

  load_gql(MeadowWeb.Schema, "test/gql/FileSetAnnotation.gql")

  @moduletag walex: [Meadow.Events.FileSets.Annotations]
  describe "FileSet annotation subscription" do
    setup [:set_mox_from_context, :verify_on_exit!]

    setup %{socket: socket} do
      %{file_sets: [file_set | _]} = work_with_file_sets_fixture(1)

      {:ok, annotation} =
        FileSets.create_annotation(file_set, %{type: "transcription", status: "in_progress"})

      {:ok, annotation} = FileSets.write_annotation_content(annotation, "Original content")

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

    test "receives completed generated annotation again after provenance is recorded", %{
      socket: socket
    } do
      use_transcriber_mock()

      work =
        work_with_file_sets_fixture(
          1,
          %{work_type: %{id: "IMAGE", scheme: "work_type"}},
          %{role: %{id: "A", scheme: "FILE_SET_ROLE"}}
        )

      %{file_sets: [file_set]} = Repo.preload(work, :file_sets)

      {:ok, _human} =
        FileSets.create_annotation(file_set, %{
          type: "transcription",
          status: "completed",
          content: "Human draft"
        })

      expect(Meadow.Data.TranscriberMock, :transcribe, fn _id, _opts ->
        {:ok, %{text: "AI improved", languages: ["en"], raw: %{}, streamed_chunks: []}}
      end)

      ref =
        subscribe_gql(socket, variables: %{"fileSetId" => file_set.id, context: gql_context()})

      assert_reply ref, :ok, %{subscriptionId: _subscription_id}, @reply_timeout

      assert {:ok, %FileSetAnnotation{id: annotation_id}} =
               FileSets.transcribe_file_set(file_set.id, context: "Human draft")

      assert_push "subscription:data",
                  %{
                    result: %{
                      data: %{
                        "fileSetAnnotation" => %{
                          "id" => ^annotation_id,
                          "status" => "completed",
                          "content" => "AI improved",
                          "aiProvenance" => %{
                            "origin" => "ai_modified_human_content",
                            "status" => "applied"
                          }
                        }
                      }
                    }
                  },
                  @reply_timeout

      # Wait for the task's final step (the work note) so it does not outlive the test
      assert_async(timeout: 2000, sleep_time: 100) do
        assert [%{type: %{id: "LOCAL_NOTE"}}] =
                 Meadow.Data.Works.get_work!(work.id).descriptive_metadata.notes
      end
    end
  end

  defp use_transcriber_mock do
    previous = Application.get_env(:meadow, :transcriber)
    Application.put_env(:meadow, :transcriber, Meadow.Data.TranscriberMock)

    on_exit(fn -> restore_transcriber(previous) end)
    :ok
  end

  defp restore_transcriber(nil), do: Application.delete_env(:meadow, :transcriber)

  defp restore_transcriber(previous), do: Application.put_env(:meadow, :transcriber, previous)
end
