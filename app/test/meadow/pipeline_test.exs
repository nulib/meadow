defmodule Meadow.Data.PipelineTest do
  @moduledoc """
  Tests for Pipeline API
  """
  use Meadow.DataCase
  use Meadow.S3Case
  use ExUnit.Case

  alias Meadow.Config
  alias Meadow.Data.{ActionStates, FileSets}
  alias Meadow.Data.Schemas.FileSet
  alias Meadow.Pipeline
  alias Meadow.Pipeline.Actions.Dispatcher
  alias Meadow.Utils.AWS

  import Assertions
  import ExUnit.CaptureLog
  import WaitForIt

  @tiff_fixture File.read!("test/fixtures/coffee.tif")
  @tiff_bucket Config.ingest_bucket()
  @tiff_key "pipeline-test/coffee.tif"
  @tiff_location "s3://#{@tiff_bucket}/#{@tiff_key}"

  @s3_fixture %{bucket: @tiff_bucket, key: @tiff_key, content: @tiff_fixture}

  @valid_attrs %{
    accession_number: "12345",
    role: %{id: "A", scheme: "FILE_SET_ROLE"},
    core_metadata: %{
      description: "yes",
      location: @tiff_location,
      original_filename: "test.tiff"
    }
  }

  describe "ingesting file set" do
    @describetag s3: [@s3_fixture]

    test "ingest_file_set/1 creates a file_set" do
      assert {:ok, %FileSet{} = _file_set} = Pipeline.ingest_file_set(@valid_attrs)
    end

    test "kickoff pipeline creates action_state records for initial common actions" do
      preservation_attrs = %{
        accession_number: "12345",
        role: %{id: "A", scheme: "FILE_SET_ROLE"},
        core_metadata: %{
          description: "yes",
          location: @tiff_location,
          original_filename: "test.tiff"
        }
      }

      {:ok, file_set} = FileSets.create_file_set(preservation_attrs)

      Pipeline.kickoff(file_set, %{role: file_set.role.id})

      assert ActionStates.get_states(file_set.id) |> length() ==
               Dispatcher.initial_actions() |> length()

      assert_lists_equal(
        ActionStates.get_states(file_set.id) |> Enum.map(fn state -> state.action end),
        [
          "Meadow.Pipeline.Actions.ExtractMimeType",
          "Meadow.Pipeline.Actions.IngestFileSet",
          "Meadow.Pipeline.Actions.InitializeDispatch"
        ]
      )

      ActionStates.get_states(file_set.id)
      |> Enum.each(fn action -> assert action.outcome == "waiting" end)
    end
  end

  describe "checksum timeout" do
    @describetag s3: [@s3_fixture]

    setup do
      wait(
        AWS.check_object_tags!(
          @tiff_bucket,
          @tiff_key,
          Config.required_checksum_tags()
        ),
        timeout: Config.checksum_wait_timeout(),
        frequency: 250
      )

      ExAws.S3.delete_object_tagging(@tiff_bucket, @tiff_key)
      |> ExAws.request!()

      old_timeout = Application.get_env(:meadow, :checksum_wait_timeout)
      Application.put_env(:meadow, :checksum_wait_timeout, 1_000)

      on_exit(fn ->
        Application.put_env(:meadow, :checksum_wait_timeout, old_timeout)
      end)

      :ok
    end

    test "ingest_file_set/1 times out waiting for checksums" do
      logged =
        capture_log(fn ->
          Pipeline.ingest_file_set(@valid_attrs)
          :timer.sleep(Config.checksum_wait_timeout() * 2)
        end)

      assert logged
             |> String.contains?("Timed out after 1000ms waiting for checksum tags")
    end
  end
end
