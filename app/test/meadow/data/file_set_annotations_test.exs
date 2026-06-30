defmodule Meadow.Data.FileSetAnnotationsTest do
  use Meadow.DataCase
  use Meadow.S3Case

  alias Meadow.AI.Provenance
  alias Meadow.Data.FileSets
  alias Meadow.Data.Schemas.FileSetAnnotation

  import Assertions
  import Meadow.TestHelpers
  import Mox

  @moduletag :capture_log

  describe "annotations" do
    setup do
      file_set = file_set_fixture()
      {:ok, file_set: file_set}
    end

    test "create_annotation/2 creates an annotation", %{file_set: file_set} do
      attrs = %{
        type: "transcription",
        status: "pending",
        language: ["en"]
      }

      assert {:ok, %FileSetAnnotation{} = annotation} =
               FileSets.create_annotation(file_set, attrs)

      assert annotation.file_set_id == file_set.id
      assert annotation.type == "transcription"
      assert annotation.status == "pending"
      assert annotation.language == ["en"]
    end

    test "create_annotation/2 enforces unique constraint on file_set_id + type", %{
      file_set: file_set
    } do
      attrs = %{type: "transcription", status: "pending"}

      assert {:ok, _annotation} = FileSets.create_annotation(file_set, attrs)
      assert {:error, changeset} = FileSets.create_annotation(file_set, attrs)

      assert %{file_set_id: ["annotation of this type already exists for this file set"]} =
               errors_on(changeset)
    end

    test "list_annotations/1 returns all annotations for a file set", %{file_set: file_set} do
      {:ok, _annotation1} =
        FileSets.create_annotation(file_set, %{type: "transcription", status: "pending"})

      annotations = FileSets.list_annotations(file_set)
      assert length(annotations) == 1
    end

    test "update_annotation/2 updates an annotation", %{file_set: file_set} do
      {:ok, annotation} =
        FileSets.create_annotation(file_set, %{type: "transcription", status: "pending"})

      assert {:ok, updated} =
               FileSets.update_annotation(annotation, %{
                 status: "completed",
                 language: ["lg", "en"]
               })

      assert updated.status == "completed"
      assert updated.language == ["lg", "en"]
    end

    test "delete_annotation/1 deletes an annotation", %{file_set: file_set} do
      {:ok, annotation} =
        FileSets.create_annotation(file_set, %{type: "transcription", status: "pending"})

      assert {:ok, _deleted} = FileSets.delete_annotation(annotation)
      assert [] = FileSets.list_annotations(file_set)
    end

    test "update_annotation/2 returns a changeset error for stale annotations", %{
      file_set: file_set
    } do
      {:ok, annotation} =
        FileSets.create_annotation(file_set, %{type: "transcription", status: "pending"})

      assert {:ok, _deleted} = FileSets.delete_annotation(annotation)

      assert {:error, changeset} =
               FileSets.update_annotation(annotation, %{status: "error"})

      assert %{id: ["is stale"]} = errors_on(changeset)
    end

    test "write_annotation_content/2 writes content to DB", %{file_set: file_set} do
      {:ok, annotation} =
        FileSets.create_annotation(file_set, %{type: "transcription", status: "pending"})

      content = "This is the transcription text"

      assert {:ok, updated} = FileSets.write_annotation_content(annotation, content)
      assert updated.content == content
    end

    test "read_annotation_content/1 reads content from DB", %{file_set: file_set} do
      {:ok, annotation} =
        FileSets.create_annotation(file_set, %{type: "transcription", status: "pending"})

      content = "This is the transcription text"

      {:ok, updated} = FileSets.write_annotation_content(annotation, content)

      assert {:ok, read_content} = FileSets.read_annotation_content(updated)
      assert read_content == content
    end

    test "update_annotation_content/3 accepts keyword opts", %{file_set: file_set} do
      {:ok, annotation} =
        FileSets.create_annotation(file_set, %{
          type: "transcription",
          status: "completed",
          language: ["en"]
        })

      {:ok, annotation} = FileSets.write_annotation_content(annotation, "Original content")

      assert {:ok, updated} =
               FileSets.update_annotation_content(annotation.id, "Updated content",
                 language: ["lg"]
               )

      assert updated.language == ["lg"]

      assert {:ok, content} = FileSets.read_annotation_content(updated)
      assert content == "Updated content"
    end

    test "update_annotation_content/3 updates both content and language", %{file_set: file_set} do
      {:ok, annotation} =
        FileSets.create_annotation(file_set, %{
          type: "transcription",
          status: "completed",
          language: ["en"]
        })

      {:ok, annotation} = FileSets.write_annotation_content(annotation, "Original content")

      assert {:ok, updated} =
               FileSets.update_annotation_content(annotation.id, "Updated content", %{
                 language: ["lg"]
               })

      assert updated.language == ["lg"]

      assert {:ok, content} = FileSets.read_annotation_content(updated)
      assert content == "Updated content"
    end
  end

  describe "transcription" do
    setup [:set_mox_from_context, :verify_on_exit!, :use_transcriber_mock]

    setup do
      file_set = file_set_fixture(role: %{id: "A", scheme: "FILE_SET_ROLE"})
      {:ok, file_set: file_set}
    end

    test "transcribe_file_set/2 marks annotation as error when text is blank", %{
      file_set: file_set
    } do
      expect(Meadow.Data.TranscriberMock, :transcribe, fn _id, _opts ->
        {:ok, %{text: "", languages: ["en"], raw: %{}, streamed_chunks: []}}
      end)

      assert {:ok, %FileSetAnnotation{id: annotation_id, status: "pending"}} =
               FileSets.transcribe_file_set(file_set.id, [])

      assert_async(timeout: 2000, sleep_time: 100) do
        assert %FileSetAnnotation{status: "error", s3_location: nil} =
                 FileSets.get_annotation!(annotation_id)
      end
    end

    test "transcribe_file_set/2 marks annotation as error when text is nil", %{
      file_set: file_set
    } do
      expect(Meadow.Data.TranscriberMock, :transcribe, fn _id, _opts ->
        {:ok, %{text: nil, languages: ["en"], raw: %{}, streamed_chunks: []}}
      end)

      assert {:ok, %FileSetAnnotation{id: annotation_id, status: "pending"}} =
               FileSets.transcribe_file_set(file_set.id, [])

      assert_async(timeout: 2000, sleep_time: 100) do
        assert %FileSetAnnotation{status: "error", s3_location: nil} =
                 FileSets.get_annotation!(annotation_id)
      end
    end

    test "transcribe_file_set/2 marks annotation as error on transcriber error", %{
      file_set: file_set
    } do
      expect(Meadow.Data.TranscriberMock, :transcribe, fn _id, _opts ->
        {:error, :bedrock_stream_failed}
      end)

      assert {:ok, %FileSetAnnotation{id: annotation_id, status: "pending"}} =
               FileSets.transcribe_file_set(file_set.id, [])

      assert_async(timeout: 2000, sleep_time: 100) do
        assert %FileSetAnnotation{status: "error"} = FileSets.get_annotation!(annotation_id)
      end
    end

    test "transcribe_file_set/2 records provenance when transcription completes" do
      work = work_fixture(%{descriptive_metadata: %{title: "Transcription Work"}})

      file_set =
        file_set_fixture(
          work_id: work.id,
          role: %{id: "A", scheme: "FILE_SET_ROLE"},
          core_metadata: %{
            label: "Page 1",
            location: "s3://bucket/page1.tif",
            original_filename: "page1.tif"
          }
        )

      expect(Meadow.Data.TranscriberMock, :transcribe, fn _id, _opts ->
        {:ok, %{text: "Transcribed text", languages: ["en"], raw: %{}, streamed_chunks: []}}
      end)

      assert {:ok, %FileSetAnnotation{id: annotation_id, ai_activity_id: activity_id}} =
               FileSets.transcribe_file_set(file_set.id, [])

      assert is_binary(activity_id)

      assert_async(timeout: 2000, sleep_time: 100) do
        assert %FileSetAnnotation{status: "completed", content: "Transcribed text"} =
                 FileSets.get_annotation!(annotation_id)

        assert [
                 %{
                   field_path: "file_set_annotations.content",
                   origin: "ai_generated",
                   applied_at: %DateTime{}
                 }
               ] = Meadow.AI.Provenance.work_summary(work.id)

        fresh_work = Meadow.Data.Works.get_work!(work.id)

        assert [%{note: note_text, type: %{id: "LOCAL_NOTE"}}] =
                 fresh_work.descriptive_metadata.notes

        assert note_text =~ "Transcription generated for Page 1 by AI"
      end
    end

    test "transcribe_file_set/2 forwards the :context option to the transcriber" do
      work = work_fixture(%{descriptive_metadata: %{title: "Context Work"}})

      file_set =
        file_set_fixture(
          work_id: work.id,
          role: %{id: "A", scheme: "FILE_SET_ROLE"},
          core_metadata: %{
            label: "Page 1",
            location: "s3://bucket/page1.tif",
            original_filename: "page1.tif"
          }
        )

      test_pid = self()

      expect(Meadow.Data.TranscriberMock, :transcribe, fn _id, opts ->
        send(test_pid, {:transcribe_opts, opts})
        {:ok, %{text: "Generated", languages: ["en"], raw: %{}, streamed_chunks: []}}
      end)

      assert {:ok, %FileSetAnnotation{}} =
               FileSets.transcribe_file_set(file_set.id, context: "Existing draft")

      assert_receive {:transcribe_opts, opts}, 2000
      assert Keyword.get(opts, :context) == "Existing draft"
    end

    test "transcribe_file_set/2 replaces a human transcription and records ai_modified_human_content" do
      work = work_fixture(%{descriptive_metadata: %{title: "Replace Work"}})

      file_set =
        file_set_fixture(
          work_id: work.id,
          role: %{id: "A", scheme: "FILE_SET_ROLE"},
          core_metadata: %{
            label: "Page 1",
            location: "s3://bucket/page1.tif",
            original_filename: "page1.tif"
          }
        )

      {:ok, _human} =
        FileSets.create_annotation(file_set, %{
          type: "transcription",
          status: "completed",
          content: "Human draft"
        })

      expect(Meadow.Data.TranscriberMock, :transcribe, fn _id, _opts ->
        {:ok, %{text: "AI improved", languages: ["en"], raw: %{}, streamed_chunks: []}}
      end)

      assert {:ok, %FileSetAnnotation{id: annotation_id}} =
               FileSets.transcribe_file_set(file_set.id, context: "Human draft")

      assert_async(timeout: 2000, sleep_time: 100) do
        assert %FileSetAnnotation{status: "completed", content: "AI improved"} =
                 FileSets.get_annotation!(annotation_id)

        assert [%{origin: "ai_modified_human_content"}] = Provenance.work_summary(work.id)
      end

      # The single (file_set, transcription) slot now holds only the new one.
      assert length(FileSets.list_annotations(file_set.id)) == 1
    end

    test "transcribe_file_set/2 without context records ai_generated even over human content" do
      work = work_fixture(%{descriptive_metadata: %{title: "Fresh Work"}})

      file_set =
        file_set_fixture(
          work_id: work.id,
          role: %{id: "A", scheme: "FILE_SET_ROLE"},
          core_metadata: %{
            label: "Page 1",
            location: "s3://bucket/page1.tif",
            original_filename: "page1.tif"
          }
        )

      {:ok, _human} =
        FileSets.create_annotation(file_set, %{
          type: "transcription",
          status: "completed",
          content: "Human draft"
        })

      expect(Meadow.Data.TranscriberMock, :transcribe, fn _id, _opts ->
        {:ok, %{text: "Fresh AI", languages: ["en"], raw: %{}, streamed_chunks: []}}
      end)

      assert {:ok, %FileSetAnnotation{id: annotation_id}} =
               FileSets.transcribe_file_set(file_set.id, [])

      assert_async(timeout: 2000, sleep_time: 100) do
        assert %FileSetAnnotation{status: "completed", content: "Fresh AI"} =
                 FileSets.get_annotation!(annotation_id)

        assert [%{origin: "ai_generated"}] = Provenance.work_summary(work.id)
      end
    end
  end

  describe "AI annotation deletion provenance" do
    setup do
      file_set = file_set_fixture()

      {:ok, activity} =
        Provenance.create_activity(%{
          activity_type: "transcription",
          ai_use_type: "transcription",
          work_id: file_set.work_id,
          file_set_id: file_set.id,
          status: "completed"
        })

      {:ok, annotation} =
        FileSets.create_annotation(file_set, %{
          type: "transcription",
          status: "completed",
          content: "AI transcription text",
          ai_activity_id: activity.id
        })

      {:ok, _target} =
        Provenance.record_target(
          activity,
          %{
            target_type: "FileSetAnnotation",
            target_id: annotation.id,
            field_path: "file_set_annotations.content",
            operation: "replace",
            proposed_value: "AI transcription text",
            origin: "ai_generated",
            status: "applied"
          },
          "applied"
        )

      {:ok, file_set: file_set, annotation: annotation, activity: activity}
    end

    test "deleting an AI transcription records a 'deleted' event on its target", %{
      annotation: annotation,
      activity: activity
    } do
      assert {:ok, _deleted} = FileSets.delete_annotation(annotation, "bmq449")

      [target] = Provenance.get_activity!(activity.id).targets
      deleted = Enum.find(target.events, &(&1.event_type == "deleted"))

      assert target.status == "deleted"
      assert target.human_oversight_level == "human_modified"
      assert target.c2pa_action == "c2pa.removed"
      assert deleted.actor == "bmq449"
      assert deleted.value_before == %{"value" => "AI transcription text"}
      assert is_nil(deleted.value_after)
      assert deleted.premis_event_type == "deletion"
    end

    test "deleting a non-AI annotation records no deletion event", %{file_set: file_set} do
      {:ok, plain} =
        FileSets.create_annotation(file_set, %{type: "caption", status: "completed"})

      assert {:ok, _deleted} = FileSets.delete_annotation(plain)

      deleted_targets =
        [work_id: file_set.work_id]
        |> Provenance.list_activities()
        |> Enum.flat_map(& &1.targets)
        |> Enum.filter(&(&1.status == "deleted"))

      assert deleted_targets == []
    end
  end

  describe "AI annotation edit provenance" do
    setup do
      file_set = file_set_fixture()

      {:ok, activity} =
        Provenance.create_activity(%{
          activity_type: "transcription",
          ai_use_type: "transcription",
          work_id: file_set.work_id,
          file_set_id: file_set.id,
          status: "completed"
        })

      {:ok, annotation} =
        FileSets.create_annotation(file_set, %{
          type: "transcription",
          status: "completed",
          content: "AI transcription text",
          ai_activity_id: activity.id
        })

      {:ok, _target} =
        Provenance.record_target(
          activity,
          %{
            target_type: "FileSetAnnotation",
            target_id: annotation.id,
            field_path: "file_set_annotations.content",
            operation: "replace",
            proposed_value: "AI transcription text",
            origin: "ai_generated",
            status: "applied"
          },
          "applied"
        )

      {:ok, file_set: file_set, annotation: annotation, activity: activity}
    end

    test "editing an AI transcription flips its origin to ai_assisted_human_modified", %{
      annotation: annotation,
      activity: activity
    } do
      assert {:ok, _updated} =
               FileSets.update_annotation_content(annotation.id, "Human-corrected text", %{
                 actor: "bmq449"
               })

      [target] = Provenance.get_activity!(activity.id).targets
      edited = Enum.find(target.events, &(&1.event_type == "human_edited"))

      assert target.origin == "ai_assisted_human_modified"
      assert target.human_oversight_level == "human_modified"
      assert target.c2pa_action == "c2pa.edited"
      assert edited.actor == "bmq449"
      assert edited.value_before == %{"value" => "AI transcription text"}
      assert edited.value_after == %{"value" => "Human-corrected text"}
      assert edited.premis_event_type == "metadata modification"
    end

    test "clearing an AI transcription records a deletion", %{
      annotation: annotation,
      activity: activity
    } do
      assert {:ok, _updated} =
               FileSets.update_annotation_content(annotation.id, "", %{actor: "bmq449"})

      [target] = Provenance.get_activity!(activity.id).targets

      assert target.status == "deleted"
      assert target.origin == "human_replacement_after_ai_suggestion"
      assert Enum.any?(target.events, &(&1.event_type == "deleted"))
    end

    test "re-saving identical content records no edit event", %{
      annotation: annotation,
      activity: activity
    } do
      assert {:ok, _updated} =
               FileSets.update_annotation_content(annotation.id, "AI transcription text", %{
                 actor: "bmq449"
               })

      [target] = Provenance.get_activity!(activity.id).targets

      assert target.origin == "ai_generated"
      refute Enum.any?(target.events, &(&1.event_type == "human_edited"))
    end

    test "editing a non-AI annotation records no edit event", %{file_set: file_set} do
      {:ok, plain} =
        FileSets.create_annotation(file_set, %{
          type: "caption",
          status: "completed",
          content: "original"
        })

      assert {:ok, _updated} =
               FileSets.update_annotation_content(plain.id, "edited", %{actor: "bmq449"})

      edited_targets =
        [work_id: file_set.work_id]
        |> Provenance.list_activities()
        |> Enum.flat_map(& &1.targets)
        |> Enum.filter(&(&1.origin == "ai_assisted_human_modified"))

      assert edited_targets == []
    end

    test "attesting an AI transcription marks it human-authored and preserves content",
         %{annotation: annotation, activity: activity} do
      assert {:ok, %FileSetAnnotation{content: "AI transcription text"}} =
               FileSets.attest_annotation_content(annotation.id,
                 actor: "bmq449",
                 reason: "Verified against the image"
               )

      [target] = Provenance.get_activity!(activity.id).targets
      attested = Enum.find(target.events, &(&1.event_type == "human_attested"))

      assert target.origin == "human_attested_after_ai"
      assert target.status == "applied"
      assert target.human_oversight_level == "human_attested"
      assert attested.actor == "bmq449"
      assert attested.notes == "Verified against the image"
      assert attested.value_before == %{"value" => "AI transcription text"}
      assert attested.value_after == %{"value" => "AI transcription text"}
    end

    test "attesting a non-AI annotation is an error and records nothing", %{file_set: file_set} do
      {:ok, plain} =
        FileSets.create_annotation(file_set, %{
          type: "caption",
          status: "completed",
          content: "human caption"
        })

      assert {:error, :no_ai_provenance} =
               FileSets.attest_annotation_content(plain.id, actor: "bmq449")
    end

    test "attesting requires an actor", %{annotation: annotation} do
      assert {:error, :missing_actor} =
               FileSets.attest_annotation_content(annotation.id, reason: "no actor")
    end
  end

  defp use_transcriber_mock(_context) do
    previous = Application.get_env(:meadow, :transcriber)
    Application.put_env(:meadow, :transcriber, Meadow.Data.TranscriberMock)

    on_exit(fn ->
      case previous do
        nil -> Application.delete_env(:meadow, :transcriber)
        value -> Application.put_env(:meadow, :transcriber, value)
      end
    end)

    :ok
  end
end
