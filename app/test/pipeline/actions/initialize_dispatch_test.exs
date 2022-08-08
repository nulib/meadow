defmodule Meadow.Pipeline.Actions.InitializeDispatchTest do
  use Meadow.S3Case
  use Meadow.DataCase
  use Meadow.IngestCase
  use Meadow.PipelineCase

  alias Meadow.Data.{ActionStates, FileSets}
  alias Meadow.Ingest.{Progress, Rows}
  alias Meadow.Pipeline.Dispatcher
  alias Meadow.Pipeline.Actions.{ExtractMimeType, IngestFileSet, InitializeDispatch}
  alias Meadow.Utils.MapList

  @bucket @ingest_bucket
  @key "generate_file_set_digests_test/test.tif"
  @content "test/fixtures/coffee.tif"

  @fixture "test/fixtures/ingest_sheet.csv"

  describe "process/2" do
    setup do
      file_set =
        file_set_fixture(%{
          accession_number: "123",
          role: %{id: "A", scheme: "FILE_SET_ROLE"},
          core_metadata: %{
            location: "s3://#{@bucket}/#{@key}",
            original_filename: "test.tif"
          }
        })

      {:ok, file_set: file_set}
    end

    @tag s3: [%{bucket: @bucket, key: @key, content: File.read!(@content)}]
    test "initializes correct action_states entries for access image file set", %{
      file_set: %{id: file_set_id} = file_set
    } do
      assert(
        {:ok, %{id: ^file_set_id}, %{}} =
          send_test_message(IngestFileSet, %{file_set_id: file_set_id}, %{})
      )

      assert(
        {:ok, %{id: ^file_set_id}, %{}} =
          send_test_message(ExtractMimeType, %{file_set_id: file_set_id}, %{})
      )

      assert(
        {:ok, %{id: ^file_set_id}, %{}} =
          send_test_message(InitializeDispatch, %{file_set_id: file_set_id}, %{})
      )

      assert(ActionStates.ok?(file_set.id, InitializeDispatch))

      file_set = FileSets.get_file_set(file_set.id)

      Enum.each(Dispatcher.dispatcher_actions(file_set), fn action ->
        assert %{outcome: "waiting"} = ActionStates.get_latest_state(file_set.id, action)
      end)
    end
  end

  describe "process/2 with ingest sheet" do
    setup do
      sheet = ingest_sheet_rows_fixture(@fixture) |> Repo.preload(:ingest_sheet_rows)
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
          role: %{id: "P", scheme: "FILE_SET_ROLE"},
          core_metadata: %{
            location: "s3://#{@bucket}/#{@key}",
            original_filename: "test.tif"
          },
          work_id: work.id
        })

      {:ok, %{row: row, file_set: file_set}}
    end

    @tag s3: [%{bucket: @bucket, key: @key, content: File.read!(@content)}]
    test "sets unused progress entries for a file set to :ok", %{
      row: row,
      file_set: %{id: file_set_id}
    } do
      Progress.initialize_entry(row, true)
      assert Progress.get_entry(row, "CreateWork") |> Map.get(:status) == "pending"

      assert Progress.get_entry(row, Meadow.Pipeline.Actions.CreatePyramidTiff)
             |> Map.get(:status) == "pending"

      assert(
        {:ok, %{id: ^file_set_id}, %{}} =
          send_test_message(IngestFileSet, %{file_set_id: file_set_id}, %{context: "Sheet"})
      )

      assert(
        {:ok, %{id: ^file_set_id}, %{}} =
          send_test_message(ExtractMimeType, %{file_set_id: file_set_id}, %{context: "Sheet"})
      )

      assert(
        {:ok, %{id: ^file_set_id}, %{}} =
          send_test_message(InitializeDispatch, %{file_set_id: file_set_id}, %{context: "Sheet"})
      )

      assert Progress.get_entry(row, Meadow.Pipeline.Actions.CreatePyramidTiff)
             |> Map.get(:status) == "ok"
    end
  end

  describe "process/2 with invalid file set role + mime type" do
    setup do
      sheet = ingest_sheet_rows_fixture(@fixture) |> Repo.preload(:ingest_sheet_rows)
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
            location: "s3://#{@bucket}/#{@key}",
            original_filename: "test.tif"
          },
          work_id: work.id
        })

      {:ok, %{row: row, file_set: file_set}}
    end

    @tag s3: [%{bucket: @bucket, key: @key, content: File.read!(@content)}]
    test "errors remaining actions and progress entries", %{
      row: row,
      file_set: %{id: file_set_id} = file_set
    } do
      Progress.initialize_entry(row, true)
      assert Progress.get_entry(row, "CreateWork") |> Map.get(:status) == "pending"

      assert Progress.get_entry(row, Meadow.Pipeline.Actions.CreatePyramidTiff)
             |> Map.get(:status) == "pending"

      assert(
        {:ok, %{id: ^file_set_id}, %{}} =
          send_test_message(IngestFileSet, %{file_set_id: file_set_id}, %{context: "Sheet"})
      )

      assert(
        {:ok, %{id: ^file_set_id}, %{}} =
          send_test_message(ExtractMimeType, %{file_set_id: file_set_id}, %{context: "Sheet"})
      )

      {:ok, %{id: ^file_set_id}} =
        FileSets.update_file_set(file_set, %{core_metadata: %{mime_type: "appliation/json"}})

      assert(
        {:error, _, %{error: "Invalid mime-type and file set role combination"}} =
          send_test_message(InitializeDispatch, %{file_set_id: file_set_id}, %{context: "Sheet"})
      )
    end
  end
end
