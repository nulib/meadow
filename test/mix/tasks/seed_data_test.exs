defmodule Mix.Tasks.Meadow.SeedDataTest do
  use ExUnit.Case, async: false
  use Meadow.S3Case

  import ExUnit.CaptureLog
  import Meadow.TestHelpers

  alias Ecto.Adapters.SQL.Sandbox
  alias Meadow.Data.Schemas.{Collection, FileSet, IndexTime, Work}
  alias Meadow.Data.{FileSets, Works}
  alias Meadow.Ingest.Schemas.{Project, Sheet}
  alias Meadow.Ingest.Sheets
  alias Meadow.Repo
  alias NimbleCSV.RFC4180, as: CSV

  @data_dir "priv/seed_data"

  describe "seed data task" do
    setup do
      with sandbox_pid <- Sandbox.start_owner!(Repo, shared: true),
           timestamp <- DateTime.utc_now() |> DateTime.to_unix(:millisecond) |> to_string() do
        File.mkdir_p!(Path.join([@data_dir, timestamp, "seed_data"]))

        File.cp_r!(
          "test/fixtures/seed_data",
          Path.join([@data_dir, timestamp, "seed_data"])
        )

        File.cp!(
          "test/fixtures/seed_data.csv",
          Path.join([@data_dir, timestamp, "seed_data.csv"])
        )

        on_exit(fn ->
          [IndexTime, FileSet, Sheet, Project, Work, Collection]
          |> Enum.each(fn schema -> Repo.delete_all(schema) end)

          Meadow.Config.buckets() |> Enum.each(&empty_bucket/1)
          Sandbox.stop_owner(sandbox_pid)
          File.rm_rf!(Path.join(@data_dir, timestamp))
        end)

        {:ok, %{timestamp: timestamp}}
      end
    end

    @tag manual: true
    test "ingests provided data based on csv file path", %{timestamp: timestamp} do
      Meadow.Pipeline.children() |> Enum.map(&start_supervised/1)

      test_data =
        [@data_dir, timestamp, "seed_data.csv"]
        |> Path.join()
        |> File.read!()
        |> CSV.parse_string(skip_headers: true)

      export_name = Path.join(timestamp, "seed_data")

      log_output = capture_log(fn -> Mix.Task.rerun("meadow.seed_data", [export_name]) end)

      assert log_output =~ "[info]  Ingest complete."
      assert Sheets.get_ingest_sheet_by_title("seed_data.csv")

      assert Works.list_works() |> length() ==
               test_data |> Enum.group_by(fn [x | _] -> x end) |> map_size()

      assert FileSets.list_file_sets() |> length() == test_data |> Enum.count()

      Meadow.Pipeline.children() |> Enum.map(&stop_supervised/1)
    end

    test "mix meadow.seed_data won't run if sheet already exists", %{timestamp: timestamp} do
      with project <- project_fixture() do
        {:ok, _} =
          Sheets.create_ingest_sheet(%{
            project_id: project.id,
            title: "seed_data.csv",
            filename: "s3://test-uploads/seed_data.csv"
          })
      end

      export_name = Path.join(timestamp, "seed_data")

      log_output =
        capture_log(fn ->
          assert catch_exit(Mix.Task.rerun("meadow.seed_data", [export_name])) == :normal
        end)

      assert log_output =~ "Sheet already exists: seed_data.csv"
    end
  end
end
