defmodule Meadow.Data.CSV.MetadataUpdateJobsTest do
  use Meadow.CSVMetadataUpdateCase
  use Meadow.IndexCase
  alias Meadow.Data.{CSV.MetadataUpdateJobs, Indexer, Works}
  alias Meadow.Data.Schemas.{CSV.MetadataUpdateJob, Work}
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

  describe "missing file" do
    @describetag source: "test/fixtures/csv/work_fixture_update.csv"

    test "create_job/1" do
      assert MetadataUpdateJobs.create_job(%{
               filename: "missing.csv",
               source: "s3://test-uploads/missing.csv",
               user: "validUser"
             }) == {:error, "s3://test-uploads/missing.csv does not exist"}
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

      with work <-
             Enum.at(works, 31)
             |> Map.get(:id)
             |> Works.get_work()
             |> Repo.preload(:metadata_update_jobs) do
        assert work.published
        assert work.visibility.id == "AUTHENTICATED"

        assert work.descriptive_metadata.date_created == [
                 %{edtf: "~1899", humanized: "circa 1899?"}
               ]

        assert work.administrative_metadata.project_proposer == [
                 "Socrates Poole",
                 "Lord Bowler"
               ]

        assert Enum.member?(work.metadata_update_jobs |> Enum.map(& &1.id), job.id)

        [_header, doc] =
          work
          |> Repo.preload(Work.required_index_preloads())
          |> Indexer.encode!(:index)
          |> decode_njson()

        assert doc |> get_in(["metadataUpdateJobs"]) == [job.id]
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

    test "update_job/2", %{create_result: {:ok, job}} do
      [
        {"pending", false},
        {"valid", false},
        {"validating", true},
        {"processing", true},
        {"invalid", false}
      ]
      |> Enum.each(fn {status, active} ->
        with result <- MetadataUpdateJobs.update_job(job, %{status: status}) do
          assert result.active == active
        end
      end)
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

  describe "controlled terms preflight failure" do
    @describetag source: "test/fixtures/csv/work_fixture_update_invalid_terms.csv"

    test "apply_job/1", %{create_result: result} do
      assert {:ok, job} = result
      assert {:error, "validation", %{errors: errors}} = MetadataUpdateJobs.apply_job(job)
      refute MetadataUpdateJobs.get_job(job.id) |> Map.get(:active)

      assert errors == [
               %{
                 errors: %{
                   "http://id.loc.gov/authorities/names/blahblah" =>
                     "is from an unknown authority",
                   "http://id.lock.gov/authorities/names/n79091588" =>
                     "is from an unknown authority"
                 },
                 row: 0
               }
             ]
    end
  end

  describe "invalid data" do
    @describetag source: "test/fixtures/csv/work_fixture_update_invalid.csv"

    test "apply_job/1", %{create_result: result} do
      assert {:ok, job} = result
      assert {:error, "validation", %{errors: errors}} = MetadataUpdateJobs.apply_job(job)
      refute MetadataUpdateJobs.get_job(job.id) |> Map.get(:active)

      assert errors == [
               %{
                 errors: %{
                   "contributor#3" => ["nop is an invalid coded term for scheme MARC_RELATOR"]
                 },
                 row: 12
               },
               %{errors: %{"id" => "NOT_A_UUID is not a valid UUID"}, row: 13},
               %{
                 errors: %{
                   "date_created" => "[%{edtf: \"bad_date\"}, %{edtf: \"201?\"}] is invalid"
                 },
                 row: 14
               },
               %{errors: %{"id" => "0bde5432-0b7b-4f80-98fb-5f7ceff98dee not found"}, row: 18},
               %{errors: %{"id" => "is required"}, row: 28},
               %{errors: %{"accession_number" => "MISMATCHED_ACCESSION does not match"}, row: 37}
             ]
    end
  end
end
