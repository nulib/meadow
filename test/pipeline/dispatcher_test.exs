defmodule Meadow.Pipeline.Actions.DispatcherTest do
  use Meadow.S3Case
  use Meadow.DataCase

  alias Meadow.Config

  alias Meadow.Pipeline.Actions.{
    CopyFileToPreservation,
    CreatePyramidTiff,
    CreateTranscodeJob,
    Dispatcher,
    ExtractExifMetadata,
    ExtractMimeType,
    FileSetComplete,
    GenerateFileSetDigests,
    IngestFileSet,
    InitializeDispatch,
    TranscodeComplete
  }

  alias Meadow.Utils.Pairtree

  import ExUnit.CaptureLog

  @bucket "test-ingest"
  @streaming_bucket Config.streaming_bucket()
  @key "generate_file_set_digests_test/test.tif"
  @content "test/fixtures/coffee.tif"

  setup do
    file_set =
      file_set_fixture(%{
        accession_number: "123",
        role: %{id: "P", scheme: "FILE_SET_ROLE"},
        core_metadata: %{
          location: "s3://#{@bucket}/#{@key}",
          original_filename: "test.tif"
        }
      })

    {:ok, file_set_id: file_set.id}
  end

  describe "process/2" do
    @tag s3: [%{bucket: @bucket, key: @key, content: File.read!(@content)}]
    test "Dispatches the next action for a file set", %{file_set_id: file_set_id} do
      assert(IngestFileSet.process(%{file_set_id: file_set_id}, %{}) == :ok)
      assert(ExtractMimeType.process(%{file_set_id: file_set_id}, %{}) == :ok)
      assert(InitializeDispatch.process(%{file_set_id: file_set_id}, %{}) == :ok)

      assert capture_log(fn ->
               Dispatcher.process(%{file_set_id: file_set_id}, %{
                 process: "InitializeDispatch",
                 status: "ok"
               })
             end) =~
               "Last action was: Elixir.Meadow.Pipeline.Actions.InitializeDispatch, next action is: Elixir.Meadow.Pipeline.Actions.GenerateFileSetDigests for file set id: #{file_set_id}"
    end
  end

  describe "action retrieval" do
    test "initial_actions" do
      assert Dispatcher.initial_actions() == [
               IngestFileSet,
               ExtractMimeType,
               InitializeDispatch
             ]
    end

    test "dispatcher_actions for file set role: P, mime_type: image/*" do
      file_set =
        file_set_fixture(%{
          role: %{id: "P", scheme: "FILE_SET_ROLE"},
          core_metadata: %{
            mime_type: "image/tiff",
            location: "s3://blahblah",
            original_filename: "test.tif"
          }
        })

      assert Dispatcher.dispatcher_actions(file_set) == [
               GenerateFileSetDigests,
               ExtractExifMetadata,
               CopyFileToPreservation,
               FileSetComplete
             ]
    end

    test "dispatcher_actions for file set role: A, mime_type: image/*" do
      file_set =
        file_set_fixture(%{
          role: %{id: "A", scheme: "FILE_SET_ROLE"},
          core_metadata: %{
            mime_type: "image/tiff",
            location: "s3://blahblah",
            original_filename: "test.tif"
          }
        })

      assert Dispatcher.dispatcher_actions(file_set) == [
               GenerateFileSetDigests,
               ExtractExifMetadata,
               CopyFileToPreservation,
               CreatePyramidTiff,
               FileSetComplete
             ]
    end

    test "dispatcher_actions for file set role: X, mime_type: image/*" do
      file_set =
        file_set_fixture(%{
          role: %{id: "X", scheme: "FILE_SET_ROLE"},
          core_metadata: %{
            mime_type: "image/tiff",
            location: "s3://blahblah",
            original_filename: "test.tif"
          }
        })

      assert Dispatcher.dispatcher_actions(file_set) == [
               GenerateFileSetDigests,
               ExtractExifMetadata,
               CopyFileToPreservation,
               CreatePyramidTiff,
               FileSetComplete
             ]
    end

    test "dispatcher_actions for file set role: S, mime_type: *" do
      file_set =
        file_set_fixture(%{
          role: %{id: "S", scheme: "FILE_SET_ROLE"},
          core_metadata: %{
            mime_type: "application/json",
            location: "s3://blahblah",
            original_filename: "test.tif"
          }
        })

      assert Dispatcher.dispatcher_actions(file_set) == [
               GenerateFileSetDigests,
               CopyFileToPreservation,
               FileSetComplete
             ]
    end

    test "dispatcher_actions for file set role: A, mime_type: audio/*" do
      file_set =
        file_set_fixture(%{
          role: %{id: "A", scheme: "FILE_SET_ROLE"},
          core_metadata: %{
            mime_type: "audio/aac",
            location: "s3://blahblah",
            original_filename: "test.aac"
          }
        })

      refute Enum.member?(Dispatcher.dispatcher_actions(file_set), ExtractExifMetadata)
      assert Enum.member?(Dispatcher.dispatcher_actions(file_set), CreateTranscodeJob)
      assert Enum.member?(Dispatcher.dispatcher_actions(file_set), TranscodeComplete)
    end

    test "dispatcher_actions for file set role: P, mime_type: audio/*" do
      file_set =
        file_set_fixture(%{
          role: %{id: "P", scheme: "FILE_SET_ROLE"},
          core_metadata: %{
            mime_type: "audio/aac",
            location: "s3://blahblah",
            original_filename: "test.aac"
          }
        })

      refute Enum.member?(Dispatcher.dispatcher_actions(file_set), ExtractExifMetadata)
      refute Enum.member?(Dispatcher.dispatcher_actions(file_set), CreateTranscodeJob)
      refute Enum.member?(Dispatcher.dispatcher_actions(file_set), TranscodeComplete)
    end

    test "dispatcher_actions for file set role: A, mime_type: video/*" do
      file_set =
        file_set_fixture(%{
          role: %{id: "A", scheme: "FILE_SET_ROLE"},
          core_metadata: %{
            mime_type: "video/mp4",
            location: "s3://blahblah",
            original_filename: "test.m4v"
          }
        })

      refute Enum.member?(Dispatcher.dispatcher_actions(file_set), ExtractExifMetadata)
      assert Enum.member?(Dispatcher.dispatcher_actions(file_set), CreateTranscodeJob)
      assert Enum.member?(Dispatcher.dispatcher_actions(file_set), TranscodeComplete)
    end

    test "dispatcher_actions for file set role: P, mime_type: video/*" do
      file_set =
        file_set_fixture(%{
          role: %{id: "P", scheme: "FILE_SET_ROLE"},
          core_metadata: %{
            mime_type: "video/mp4",
            location: "s3://blahblah",
            original_filename: "test.m4v"
          }
        })

      refute Enum.member?(Dispatcher.dispatcher_actions(file_set), ExtractExifMetadata)
      refute Enum.member?(Dispatcher.dispatcher_actions(file_set), CreateTranscodeJob)
      refute Enum.member?(Dispatcher.dispatcher_actions(file_set), TranscodeComplete)
    end

    test "dispatcher_actions for unknown mime type" do
      file_set =
        file_set_fixture(%{
          role: %{id: "A", scheme: "FILE_SET_ROLE"},
          core_metadata: %{
            mime_type: "application/octet-stream",
            location: "s3://blahblah",
            original_filename: "test.tif"
          }
        })

      assert Dispatcher.dispatcher_actions(file_set) == nil
    end
  end

  describe "playlist exists" do
    setup do
      file_set =
        file_set_fixture(%{
          role: %{id: "P", scheme: "FILE_SET_ROLE"},
          core_metadata: %{
            mime_type: "video/mp4",
            location: "s3://blahblah",
            original_filename: "test.m4v"
          }
        })

      upload_object(
        @streaming_bucket,
        Pairtree.generate!(file_set.id),
        File.read!(@content)
      )

      on_exit(fn ->
        empty_bucket(@streaming_bucket)
      end)

      {:ok, file_set: file_set}
    end

    test "dispatcher_actions for A/V file set where playlist exists skips trancoding steps", %{
      file_set: file_set
    } do
      assert Enum.member?(Dispatcher.dispatcher_actions(file_set), CopyFileToPreservation)
      refute Enum.member?(Dispatcher.dispatcher_actions(file_set), CreateTranscodeJob)
      refute Enum.member?(Dispatcher.dispatcher_actions(file_set), TranscodeComplete)
    end

    test "dispatches to FileSetComplete after TranscodeComplete even if skip_transcode? is true",
         %{file_set: file_set} do
      assert capture_log(fn ->
               Dispatcher.process(%{file_set_id: file_set.id}, %{
                 process: "TranscodeComplete",
                 status: "ok"
               })
             end) =~
               "Last action was: Elixir.Meadow.Pipeline.Actions.TranscodeComplete, next action is: Elixir.Meadow.Pipeline.Actions.FileSetComplete for file set id: #{file_set.id}"
    end
  end
end
