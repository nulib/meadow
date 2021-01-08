defmodule Meadow.Data.CSV.MetadataUpdateJobsTest do
  use Meadow.CSVMetadataUpdateCase
  alias Meadow.Data.CSV.MetadataUpdateJobs
  alias Meadow.Data.Schemas.CSV.MetadataUpdateJob
  alias Meadow.Data.Works
  alias Meadow.Repo

  setup %{source_url: source_url} do
    with filename <- Path.basename(source_url) do
      {:ok,
       %{
         create_result:
           MetadataUpdateJobs.create_job(%{
             filename: filename,
             source: source_url,
             user: "validUser"
           })
       }}
    end
  end

  describe "valid data" do
    @describetag source: "test/fixtures/csv/work_fixture_update.csv"

    test "create_job/1", %{create_result: result} do
      assert {:ok, job} = result
      assert job.status == "pending"
      assert job.rows |> is_nil()
    end

    test "list_jobs/0", %{create_result: {:ok, job}} do
      assert MetadataUpdateJobs.list_jobs() == [job]
    end

    test "get_job/1", %{create_result: {:ok, job}} do
      assert MetadataUpdateJobs.get_job(job.id) == job
    end

    test "apply_job/1", %{create_result: {:ok, job}, works: works} do
      refute job.started_at
      assert {:ok, job} = MetadataUpdateJobs.apply_job(job)
      assert job.status == "complete"
      assert job.started_at

      assert MetadataUpdateJobs.apply_job(job) ==
               {:error, "Update Job cannot be applied: status is complete."}

      with work <- Enum.at(works, 31) |> Map.get(:id) |> Works.get_work() do
        assert work.published
        assert work.visibility.id == "AUTHENTICATED"

        assert work.descriptive_metadata.date_created == [
                 %{edtf: "~1899", humanized: "circa 1899?"}
               ]

        assert work.administrative_metadata.project_proposer == [
                 "Socrates Poole",
                 "Lord Bowler"
               ]
      end
    end

    test "next_job/0", %{create_result: {:ok, job}} do
      assert MetadataUpdateJobs.next_job() == job
      job |> MetadataUpdateJobs.update_job(%{active: true})
      assert MetadataUpdateJobs.next_job() |> is_nil()
    end

    test "reset_stalled/1" do
      with timestamp <- NaiveDateTime.utc_now() |> NaiveDateTime.add(-400, :second) do
        Repo.update_all(MetadataUpdateJob, set: [updated_at: timestamp])
        assert MetadataUpdateJobs.reset_stalled(360) == {:ok, 0}

        Repo.update_all(MetadataUpdateJob, set: [updated_at: timestamp, status: "validating"])
        assert MetadataUpdateJobs.reset_stalled(360) == {:ok, 1}

        Repo.update_all(MetadataUpdateJob, set: [updated_at: timestamp, status: "processing"])
        assert MetadataUpdateJobs.reset_stalled(360) == {:ok, 1}
      end
    end
  end

  describe "bad headers" do
    @describetag source: "test/fixtures/csv/work_fixture_update_bad_headers.csv"

    test "apply_job/1", %{create_result: result} do
      assert {:ok, job} = result
      assert {:error, "validation", %{errors: errors}} = MetadataUpdateJobs.apply_job(job)

      assert errors == [
               %{errors: %{published: ["is missing"], publishedd: ["is unknown"]}, row: 1}
             ]
    end
  end

  describe "invalid data" do
    @describetag source: "test/fixtures/csv/work_fixture_update_invalid.csv"

    test "apply_job/1", %{create_result: result} do
      assert {:ok, job} = result
      assert {:error, "validation", %{errors: errors}} = MetadataUpdateJobs.apply_job(job)

      assert errors == [
               %{
                 errors: %{
                   "contributor#3" => ["nop is an invalid coded term for scheme MARC_RELATOR"]
                 },
                 row: 12
               },
               %{
                 errors: %{
                   "date_created" => ~s([%{edtf: "bad_date"}, %{edtf: "201?"}] is invalid)
                 },
                 row: 14
               }
             ]
    end
  end
end
