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
  alias Meadow.Ingest.{Progress, Rows}
  alias Meadow.Pipeline
  alias Meadow.Pipeline.{Action, Dispatcher}

  alias Meadow.Pipeline.Actions.{
    CopyFileToPreservation,
    ExtractExifMetadata,
    ExtractMimeType,
    GenerateFileSetDigests,
    IngestFileSet,
    InitializeDispatch
  }

  alias Meadow.Utils.MapList

  import Assertions
  import ExUnit.CaptureLog

  @tiff_fixture File.read!("test/fixtures/coffee.tif")
  @tiff_bucket @ingest_bucket
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

  describe "pipeline configuration" do
    test "Meadow.Config.Pipeline.configuration_for/1 returns the correct configuration" do
      action = Meadow.Pipeline.Actions.IngestFileSet
      config = Meadow.Config.Pipeline.configuration_for(action)

      assert is_list(config)
      assert Keyword.has_key?(config, :producer)
      assert Keyword.has_key?(config, :processors)
      assert get_in(config, [:producer, :config, :region]) == Meadow.AWS.region()
    end
  end

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

  describe "replacing a file set" do
    @describetag s3: [@s3_fixture]

    test "replace_the_file_set/1 updates a file_set location" do
      file_set =
        file_set_fixture(%{
          accession_number: "12345",
          role: %{id: "A", scheme: "FILE_SET_ROLE"},
          mime_type: "image/png",
          core_metadata: %{
            description: "yes",
            location: "s3://old-location",
            original_filename: "test.png"
          }
        })

      attrs = %{core_metadata: %{location: @tiff_location}}
      assert {:ok, %FileSet{} = updated_file_set} = Pipeline.replace_the_file_set(file_set, attrs)
      assert updated_file_set.core_metadata.location == @tiff_location
    end
  end

  describe "checksum timeout" do
    @describetag s3: [@s3_fixture]

    setup do
      old_config = Application.get_all_env(:meadow)
      Application.put_env(:meadow, :checksum_wait_timeout, 1_000)
      Application.put_env(:meadow, :required_checksum_tags, ["this-tag-never-happens"])

      on_exit(fn ->
        Application.put_all_env(meadow: old_config)
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

  describe "retry/1" do
    @failed_action CopyFileToPreservation
    @succeeded_actions [
      IngestFileSet,
      ExtractMimeType,
      InitializeDispatch,
      GenerateFileSetDigests,
      ExtractExifMetadata
    ]

    setup do
      sheet =
        ingest_sheet_rows_fixture("test/fixtures/ingest_sheet.csv")
        |> Repo.preload(:ingest_sheet_rows)

      [_ | [row | _]] = Rows.list_ingest_sheet_rows(sheet: sheet)

      work =
        work_fixture(%{
          accession_number: MapList.get(row.fields, :header, :value, :work_accession_number),
          work_type: %{id: "IMAGE", scheme: "work_type"},
          ingest_sheet_id: sheet.id
        })

      file_set =
        file_set_fixture(%{
          accession_number: row.file_set_accession_number,
          role: %{id: "A", scheme: "FILE_SET_ROLE"},
          core_metadata: %{
            location: @tiff_location,
            original_filename: "test.tiff",
            mime_type: "image/tiff"
          },
          work_id: work.id
        })

      {:ok, row} = Rows.associate_file_set_with_row(row, file_set)

      {:ok, sheet: sheet, row: row, file_set: file_set}
    end

    test "restarts the pipeline from the first failed action", %{file_set: file_set} do
      fail_pipeline_at(file_set, @failed_action)
      purge_queue(@failed_action)

      assert {:ok, @failed_action} = Pipeline.retry(file_set)

      assert %{"Message" => %{"file_set_id" => file_set_id}} =
               next_message(@failed_action, file_set.id)

      assert file_set_id == file_set.id
    end

    test "passes the sheet and row along so sheet progress is updated", %{
      sheet: sheet,
      row: row,
      file_set: file_set
    } do
      fail_pipeline_at(file_set, @failed_action)
      purge_queue(@failed_action)

      assert {:ok, @failed_action} = Pipeline.retry(file_set)

      assert %{"MessageAttributes" => attributes} = next_message(@failed_action, file_set.id)

      assert get_in(attributes, ["context", "Value"]) == "Sheet"
      assert get_in(attributes, ["role", "Value"]) == "A"
      assert get_in(attributes, ["ingest_sheet", "Value"]) == sheet.id
      assert get_in(attributes, ["ingest_sheet_row", "Value"]) == row.row
    end

    test "clears failed action states and leaves successful ones alone", %{file_set: file_set} do
      fail_pipeline_at(file_set, @failed_action)

      assert {:ok, _} = Pipeline.retry(file_set)

      Enum.each(@succeeded_actions, fn action ->
        assert ActionStates.ok?(file_set.id, action)
      end)

      refute ActionStates.error?(file_set.id)

      assert ActionStates.get_latest_state(file_set.id, @failed_action)
             |> Map.get(:outcome) == "waiting"

      assert ActionStates.get_latest_state(file_set.id, @failed_action)
             |> Map.get(:notes) == nil
    end

    test "resets the row's failed progress entries to pending", %{
      row: row,
      file_set: file_set
    } do
      fail_pipeline_at(file_set, @failed_action)

      assert {:ok, _} = Pipeline.retry(file_set)

      assert Progress.get_entry(row, @failed_action) |> Map.get(:status) == "pending"
      assert Progress.get_entry(row, ExtractMimeType) |> Map.get(:status) == "ok"
    end

    test "leaves the pipeline alone when nothing has failed", %{file_set: file_set} do
      Enum.each(@succeeded_actions, &ActionStates.set_state!(file_set, &1, "ok"))

      assert {:error, :no_failures} = Pipeline.retry(file_set)
    end

    test "returns an error for an unknown file set" do
      assert {:error, :not_found} = Pipeline.retry(Ecto.UUID.generate())
    end

    test "accepts a file set id as well as a struct", %{file_set: file_set} do
      fail_pipeline_at(file_set, @failed_action)

      assert {:ok, @failed_action} = Pipeline.retry(file_set.id)
    end
  end

  describe "retry/1 without an ingest sheet" do
    setup do
      file_set =
        file_set_fixture(%{
          accession_number: "retry-no-sheet",
          role: %{id: "A", scheme: "FILE_SET_ROLE"},
          core_metadata: %{
            location: @tiff_location,
            original_filename: "test.tiff",
            mime_type: "image/tiff"
          }
        })

      {:ok, file_set: file_set}
    end

    test "restarts without sheet metadata", %{file_set: file_set} do
      fail_pipeline_at(file_set, CopyFileToPreservation)
      purge_queue(CopyFileToPreservation)

      assert {:ok, CopyFileToPreservation} = Pipeline.retry(file_set)

      assert %{"MessageAttributes" => attributes} =
               next_message(CopyFileToPreservation, file_set.id)

      assert get_in(attributes, ["role", "Value"]) == "A"
      refute Map.has_key?(attributes, "ingest_sheet")
      refute Map.has_key?(attributes, "ingest_sheet_row")
    end
  end

  # Put the file set in the state the pipeline leaves behind when `action` fails:
  # everything before it succeeded, `action` errored, and everything after it was
  # aborted. Progress entries for the file set's row, if it has one, are updated
  # to match.
  defp fail_pipeline_at(file_set, action) do
    actions = Dispatcher.initial_actions() ++ Dispatcher.dispatcher_actions(file_set, %{})
    {succeeded, [^action | aborted]} = Enum.split_while(actions, &(&1 != action))

    row = Repo.preload(file_set, :ingest_sheet_row) |> Map.get(:ingest_sheet_row)
    if row, do: Progress.initialize_entry(row, true)

    Enum.each(succeeded, fn a ->
      ActionStates.set_state!(file_set, a, "ok")
      if row, do: Progress.update_entry(row, a, "ok")
    end)

    ActionStates.set_state!(file_set, action, "error", "something went wrong")
    if row, do: Progress.update_entry(row, action, "error")

    Enum.each(aborted, fn a ->
      ActionStates.set_state!(file_set, a, "error", "Previous action failed")
      if row, do: Progress.update_entry(row, a, "error")
    end)
  end

  defp purge_queue(action) do
    Action.queue_url(action) |> Meadow.AWS.SQS.purge_queue()
  end

  # Pull messages off the action's queue until the one for `file_set_id` turns up.
  defp next_message(action, file_set_id, attempts \\ 5) do
    url = Action.queue_url(action)

    Enum.reduce_while(1..attempts, nil, fn _, _ ->
      case receive_one(url) do
        %{"Message" => %{"file_set_id" => ^file_set_id}} = body -> {:halt, body}
        nil -> {:halt, nil}
        _ -> {:cont, nil}
      end
    end)
  end

  defp receive_one(url) do
    Meadow.AWS.client(:sqs)
    |> AWS.SQS.receive_message(%{
      "QueueUrl" => url,
      "MaxNumberOfMessages" => 1,
      "WaitTimeSeconds" => 1
    })
    |> case do
      {:ok, %{"Messages" => [%{"Body" => body} | _]}, _} -> Jason.decode!(body)
      _ -> nil
    end
  end
end
