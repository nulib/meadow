defmodule Meadow.Data.FileSetAnnotationsTest do
  use Meadow.DataCase
  use Meadow.S3Case

  alias Meadow.Data.FileSets
  alias Meadow.Data.Schemas.FileSetAnnotation

  import Meadow.TestHelpers

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

      assert {:ok, %FileSetAnnotation{} = annotation} = FileSets.create_annotation(file_set, attrs)
      assert annotation.file_set_id == file_set.id
      assert annotation.type == "transcription"
      assert annotation.status == "pending"
      assert annotation.language == ["en"]
    end

    test "create_annotation/2 enforces unique constraint on file_set_id + type", %{file_set: file_set} do
      attrs = %{type: "transcription", status: "pending"}

      assert {:ok, _annotation} = FileSets.create_annotation(file_set, attrs)
      assert {:error, changeset} = FileSets.create_annotation(file_set, attrs)
      assert %{file_set_id: ["annotation of this type already exists for this file set"]} = errors_on(changeset)
    end

    test "list_annotations/1 returns all annotations for a file set", %{file_set: file_set} do
      {:ok, _annotation1} = FileSets.create_annotation(file_set, %{type: "transcription", status: "pending"})

      annotations = FileSets.list_annotations(file_set)
      assert length(annotations) == 1
    end

    test "update_annotation/2 updates an annotation", %{file_set: file_set} do
      {:ok, annotation} = FileSets.create_annotation(file_set, %{type: "transcription", status: "pending"})

      assert {:ok, updated} = FileSets.update_annotation(annotation, %{status: "completed", language: ["lg", "en"]})
      assert updated.status == "completed"
      assert updated.language == ["lg", "en"]
    end

    test "delete_annotation/1 deletes an annotation", %{file_set: file_set} do
      {:ok, annotation} = FileSets.create_annotation(file_set, %{type: "transcription", status: "pending"})

      assert {:ok, _deleted} = FileSets.delete_annotation(annotation)
      assert [] = FileSets.list_annotations(file_set)
    end

    test "write_annotation_content/2 writes content to S3", %{file_set: file_set} do
      {:ok, annotation} = FileSets.create_annotation(file_set, %{type: "transcription", status: "pending"})
      content = "This is the transcription text"

      assert {:ok, s3_location} = FileSets.write_annotation_content(annotation, content)
      assert String.starts_with?(s3_location, "s3://")
    end

    test "read_annotation_content/1 reads content from S3", %{file_set: file_set} do
      {:ok, annotation} = FileSets.create_annotation(file_set, %{type: "transcription", status: "pending"})
      content = "This is the transcription text"

      {:ok, s3_location} = FileSets.write_annotation_content(annotation, content)
      {:ok, annotation} = FileSets.update_annotation(annotation, %{s3_location: s3_location})

      assert {:ok, read_content} = FileSets.read_annotation_content(annotation)
      assert read_content == content
    end

    test "update_annotation_content/3 updates both content and language", %{file_set: file_set} do
      {:ok, annotation} = FileSets.create_annotation(file_set, %{type: "transcription", status: "completed", language: ["en"]})
      {:ok, s3_location} = FileSets.write_annotation_content(annotation, "Original content")
      {:ok, annotation} = FileSets.update_annotation(annotation, %{s3_location: s3_location})

      assert {:ok, updated} = FileSets.update_annotation_content(annotation.id, "Updated content", %{language: ["lg"]})
      assert updated.language == ["lg"]

      assert {:ok, content} = FileSets.read_annotation_content(updated)
      assert content == "Updated content"
    end
  end
end
