defmodule Meadow.Data.TranscriberTest do
  use Meadow.DataCase
  use Meadow.S3Case

  alias Meadow.Data.{FileSets, Transcriber}

  @moduletag :capture_log

  describe "error handling" do
    test "returns error for non-existent file set" do
      fake_id = Ecto.UUID.generate()

      assert {:error, {:file_set_not_found, ^fake_id}} = Transcriber.transcribe(fake_id)
    end

    test "returns error for file set without representative image" do
      file_set = file_set_fixture()

      # Update to remove derivatives
      {:ok, file_set} = FileSets.update_file_set(file_set, %{derivatives: %{}})

      assert {:error, {:no_representative_image, _}} = Transcriber.transcribe(file_set.id)
    end
  end

  describe "integration tests" do
    @tag :skip
    @tag :manual
    test "transcribes a file set with real AWS Bedrock" do
      # This test requires actual AWS credentials and a file set with a representative image
      # Run manually with: mix test test/meadow/data/transcriber_test.exs --include manual
      file_set = file_set_fixture()

      assert {:ok, result} = Transcriber.transcribe(file_set.id)
      assert %{text: text, raw: raw, streamed_chunks: chunks} = result
      assert is_binary(text)
      assert is_map(raw)
      assert is_list(chunks)

      assert Map.has_key?(raw, "usage") or Map.has_key?(raw, "metrics")

      assert Enum.any?(chunks, fn chunk ->
               Map.has_key?(chunk, "delta") or Map.has_key?(chunk, "start")
             end)
    end

    @tag :skip
    @tag :manual
    test "transcribed text does not contain preamble when using tool use" do
      file_set = file_set_fixture()

      assert {:ok, %{text: text}} = Transcriber.transcribe(file_set.id)

      refute String.starts_with?(String.downcase(text), "here")
      refute String.starts_with?(String.downcase(text), "the transcription")
      refute String.contains?(String.downcase(text), "here is the")
    end
  end
end
