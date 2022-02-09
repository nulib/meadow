defmodule Meadow.CSVMetadataUpdateDriverTest do
  use Meadow.CSVMetadataUpdateCase

  alias Meadow.CSVMetadataUpdateDriver
  alias Meadow.Data.CSV.MetadataUpdateJobs
  alias Meadow.Data.Schemas.CSV.MetadataUpdateJob
  alias Meadow.Repo

  import ExUnit.CaptureLog

  @state %{interval: 5_000, status: :running}

  setup %{source_url: source_url} do
    with {:ok, job} <- MetadataUpdateJobs.create_job(%{source: source_url}) do
      {:ok, %{job: job}}
    end
  end

  describe "drive_update_job/1" do
    @describetag source: "test/fixtures/csv/sheets/valid.csv"

    test "runs the job", %{job: %{id: job_id}} do
      assert MetadataUpdateJobs.get_job(job_id) |> Map.get(:status) == "pending"
      assert CSVMetadataUpdateDriver.drive_update_job(@state) == {:noreply, @state}
      assert MetadataUpdateJobs.get_job(job_id) |> Map.get(:status) == "complete"
    end

    test "redrives stalled jobs", %{job: job} do
      log =
        capture_log(fn ->
          with timestamp <- NaiveDateTime.utc_now() |> NaiveDateTime.add(-400, :second) do
            Repo.update_all(MetadataUpdateJob, set: [updated_at: timestamp, status: "processing"])
          end

          assert CSVMetadataUpdateDriver.drive_update_job(@state) == {:noreply, @state}
          assert MetadataUpdateJobs.get_job(job.id) |> Map.get(:status) == "complete"
        end)

      assert log |> String.contains?("Resetting 1 stalled update job")
    end

    test "cancels jobs that exceed retries", %{job: job} do
      log =
        capture_log(fn ->
          with timestamp <- NaiveDateTime.utc_now() |> NaiveDateTime.add(-400, :second) do
            Repo.update_all(MetadataUpdateJob,
              set: [updated_at: timestamp, status: "processing", retries: 3]
            )
          end

          assert CSVMetadataUpdateDriver.drive_update_job(@state) == {:noreply, @state}
          assert MetadataUpdateJobs.get_job(job.id) |> Map.get(:status) == "error"
        end)

      assert log |> String.contains?("Canceling 1 update job jobs for exceeding max retries")
    end
  end
end
