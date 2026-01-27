defmodule Meadow.Pipeline.Actions.AttachTranscriptionTest do
  use Meadow.S3Case
  use Meadow.DataCase
  use Meadow.PipelineCase

  alias Meadow.Data.{ActionStates, FileSets}
  alias Meadow.Pipeline.Actions.AttachTranscription

  import ExUnit.CaptureLog

  @ingest_bucket Meadow.Config.ingest_bucket()
  @derivatives_bucket Meadow.Config.derivatives_bucket()
  @preservation_bucket Meadow.Config.preservation_bucket()
  @transcription_content "test/fixtures/transcription.txt"
  @transcription_key "attach_transcription_test/transcription.txt"
  @transcription_fixture %{bucket: @ingest_bucket, key: @transcription_key, content: File.read!(@transcription_content)}

  describe "success" do
    @describetag s3: [@transcription_fixture]

    setup do
      id = Ecto.UUID.generate()
      file_set =
        file_set_fixture(%{
          id: id,
          accession_number: "1234",
          role: %{id: "A", scheme: "FILE_SET_ROLE"},
          core_metadata: %{
            location: "s3://#{@preservation_bucket}/#{id}",
            original_filename: "attach_transcription_test.tif"
          },
          derivatives: %{
            "transcription_file" =>
              "s3://#{@ingest_bucket}/#{@transcription_key}"
          }
        })

      on_exit(fn ->
        empty_bucket(@ingest_bucket)
        empty_bucket(@derivatives_bucket)
      end)

      {:ok, file_set_id: file_set.id}
    end

    test "process/2", %{file_set_id: file_set_id} do
      assert(
        {:ok, %{id: ^file_set_id}, %{}} =
          send_test_message(AttachTranscription, %{file_set_id: file_set_id}, %{})
      )

      assert(ActionStates.ok?(file_set_id, AttachTranscription))

      file_set = FileSets.get_file_set!(file_set_id)
      annotations = FileSets.list_annotations(file_set)
      assert length(annotations) == 1

      annotation = List.first(annotations)
      assert annotation.type == "transcription"
      assert annotation.status == "completed"
      assert annotation.s3_location

      # Verify content was copied to S3
      {:ok, content} = FileSets.read_annotation_content(annotation)
      assert content == "This is the transcription for the image!"
    end
  end

  describe "no transcription specified" do
    setup do
      id = Ecto.UUID.generate()
      file_set =
        file_set_fixture(%{
          id: id,
          accession_number: "1234",
          role: %{id: "A", scheme: "FILE_SET_ROLE"},
          core_metadata: %{
            location: "s3://#{@preservation_bucket}/#{id}",
            original_filename: "attach_transcription_test.tif"
          }
        })

      {:ok, file_set_id: file_set.id}
    end

    test "process/2 no-op", %{file_set_id: file_set_id} do
      assert(
        {:ok, %{id: ^file_set_id}, %{}} =
          send_test_message(AttachTranscription, %{file_set_id: file_set_id}, %{})
      )

      assert(ActionStates.ok?(file_set_id, AttachTranscription))

      file_set = FileSets.get_file_set!(file_set_id)
      annotations = FileSets.list_annotations(file_set)
      assert annotations |> Enum.empty?()
    end
  end

  describe "transcription file missing" do
    setup do
      id = Ecto.UUID.generate()
      file_set =
        file_set_fixture(%{
          id: id,
          accession_number: "1234",
          role: %{id: "A", scheme: "FILE_SET_ROLE"},
          core_metadata: %{
            location: "s3://#{@preservation_bucket}/#{id}",
            original_filename: "attach_transcription_test.tif"
          },
          derivatives: %{
            "transcription_file" =>
              "s3://#{@ingest_bucket}/#{@transcription_key}"
          }
        })

      {:ok, file_set_id: file_set.id}
    end

    test "process/2 error", %{file_set_id: file_set_id} do
      log = capture_log(fn ->
        assert(
          {:error, %{id: ^file_set_id}, %{}} =
            send_test_message(AttachTranscription, %{file_set_id: file_set_id}, %{})
        )

        assert(ActionStates.error?(file_set_id, AttachTranscription))

        file_set = FileSets.get_file_set!(file_set_id)
        annotations = FileSets.list_annotations(file_set)
        assert annotations |> Enum.empty?()
      end)
      assert log =~ "Failed to copy transcription content"
    end
  end
end
