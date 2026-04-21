defmodule Meadow.Data.FileSetAnnotationsTest do
  use Meadow.DataCase
  use Meadow.S3Case

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

    test "write_annotation_content/2 writes content to S3", %{file_set: file_set} do
      {:ok, annotation} =
        FileSets.create_annotation(file_set, %{type: "transcription", status: "pending"})

      content = "This is the transcription text"

      assert {:ok, s3_location} = FileSets.write_annotation_content(annotation, content)
      assert String.starts_with?(s3_location, "s3://")
    end

    test "read_annotation_content/1 reads content from S3", %{file_set: file_set} do
      {:ok, annotation} =
        FileSets.create_annotation(file_set, %{type: "transcription", status: "pending"})

      content = "This is the transcription text"

      {:ok, s3_location} = FileSets.write_annotation_content(annotation, content)
      {:ok, annotation} = FileSets.update_annotation(annotation, %{s3_location: s3_location})

      assert {:ok, read_content} = FileSets.read_annotation_content(annotation)
      assert read_content == content
    end

    test "update_annotation_content/3 accepts keyword opts", %{file_set: file_set} do
      {:ok, annotation} =
        FileSets.create_annotation(file_set, %{
          type: "transcription",
          status: "completed",
          language: ["en"]
        })

      {:ok, s3_location} = FileSets.write_annotation_content(annotation, "Original content")
      {:ok, annotation} = FileSets.update_annotation(annotation, %{s3_location: s3_location})

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

      {:ok, s3_location} = FileSets.write_annotation_content(annotation, "Original content")
      {:ok, annotation} = FileSets.update_annotation(annotation, %{s3_location: s3_location})

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

    test "process_transcription/2 marks annotation as error when text is blank", %{
      file_set: file_set
    } do
      {:ok, annotation} =
        FileSets.create_annotation(file_set, %{type: "transcription", status: "pending"})

      expect(Meadow.Data.TranscriberMock, :transcribe, fn _id, _opts ->
        {:ok, %{text: "", languages: ["en"], raw: %{}, streamed_chunks: []}}
      end)

      assert {:ok, updated} = FileSets.process_transcription(annotation, [])
      assert updated.status == "error"
      assert is_nil(updated.s3_location)
    end

    test "process_transcription/2 marks annotation as error when text is nil", %{
      file_set: file_set
    } do
      {:ok, annotation} =
        FileSets.create_annotation(file_set, %{type: "transcription", status: "pending"})

      expect(Meadow.Data.TranscriberMock, :transcribe, fn _id, _opts ->
        {:ok, %{text: nil, languages: ["en"], raw: %{}, streamed_chunks: []}}
      end)

      assert {:ok, updated} = FileSets.process_transcription(annotation, [])
      assert updated.status == "error"
      assert is_nil(updated.s3_location)
    end

    test "process_transcription/2 marks annotation as error on transcriber error", %{
      file_set: file_set
    } do
      {:ok, annotation} =
        FileSets.create_annotation(file_set, %{type: "transcription", status: "pending"})

      expect(Meadow.Data.TranscriberMock, :transcribe, fn _id, _opts ->
        {:error, :bedrock_stream_failed}
      end)

      assert {:ok, updated} = FileSets.process_transcription(annotation, [])
      assert updated.status == "error"
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
