defmodule Meadow.Pipeline.Actions.GenerateFileSetDigestsTest do
  use Meadow.S3Case
  use Meadow.DataCase
  alias Meadow.Data.{ActionStates, FileSets}
  alias Meadow.Pipeline.Actions.GenerateFileSetDigests
  import ExUnit.CaptureLog

  @bucket "test-ingest"
  @key "generate_file_set_digests_test/test.tif"
  @content "test/fixtures/coffee.tif"
  @fixture %{bucket: @bucket, key: @key, content: File.read!(@content)}
  @sha256 "509ecd36cbb1ba4dc57430de5418ad64cf106aa209ca839ef753fa853c972753"
  @sha1 "0f4e109d2a4c8f954e940ceb356b40bd393120d0"

  setup do
    file_set =
      file_set_fixture(%{
        accession_number: "123",
        role: %{id: "A", scheme: "FILE_SET_ROLE"},
        metadata: %{
          location: "s3://#{@bucket}/#{@key}",
          original_filename: "test.tif"
        }
      })

    {:ok, file_set_id: file_set.id}
  end

  @tag s3: [@fixture]
  test "process/2", %{file_set_id: file_set_id} do
    assert(GenerateFileSetDigests.process(%{file_set_id: file_set_id}, %{}) == :ok)
    assert(ActionStates.ok?(file_set_id, GenerateFileSetDigests))

    file_set = FileSets.get_file_set!(file_set_id)
    assert(file_set.metadata.digests == %{"sha256" => @sha256, "sha1" => @sha1})

    assert capture_log(fn ->
             GenerateFileSetDigests.process(%{file_set_id: file_set_id}, %{})
           end) =~ "Skipping #{GenerateFileSetDigests} for #{file_set_id} – already complete"
  end

  describe "overwrite flag" do
    @describetag s3: [@fixture]

    setup %{file_set_id: file_set_id} do
      FileSets.get_file_set!(file_set_id)
      |> FileSets.update_file_set(%{metadata: %{digests: %{sha1: @sha1, sha256: @sha256}}})

      :ok
    end

    test "overwrite", %{file_set_id: file_set_id} do
      log =
        capture_log(fn ->
          assert(GenerateFileSetDigests.process(%{file_set_id: file_set_id}, %{}) == :ok)
          assert(ActionStates.ok?(file_set_id, GenerateFileSetDigests))
          file_set = FileSets.get_file_set!(file_set_id)
          assert(file_set.metadata.digests == %{"sha256" => @sha256, "sha1" => @sha1})
        end)

      refute log =~ ~r/already complete without overwriting/
    end

    test "retain", %{file_set_id: file_set_id} do
      log =
        capture_log(fn ->
          assert(
            GenerateFileSetDigests.process(%{file_set_id: file_set_id}, %{overwrite: "false"}) ==
              :ok
          )

          assert(ActionStates.ok?(file_set_id, GenerateFileSetDigests))
          file_set = FileSets.get_file_set!(file_set_id)
          assert(file_set.metadata.digests == %{"sha256" => @sha256, "sha1" => @sha1})
        end)

      assert log =~ ~r/already complete without overwriting/
    end
  end
end
