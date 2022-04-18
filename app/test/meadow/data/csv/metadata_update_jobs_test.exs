defmodule Meadow.Data.CSV.MetadataUpdateJobsTest do
  use Meadow.DataCase
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
    @describetag source: "test/fixtures/csv/sheets/valid.csv"

    test "create_job/1" do
      assert MetadataUpdateJobs.create_job(%{
               filename: "missing.csv",
               source: "s3://#{@upload_bucket}/missing.csv",
               user: "validUser"
             }) == {:error, "s3://#{@upload_bucket}/missing.csv does not exist"}
    end
  end

  describe "valid data" do
    @describetag source: "test/fixtures/csv/sheets/valid.csv"

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
        assert MetadataUpdateJobs.reset_stalled(360) == {:ok, 0, 0}
        assert %{status: status, retries: retries} = MetadataUpdateJob |> Repo.one()
        assert status == "pending"
        assert retries == 0

        Repo.update_all(MetadataUpdateJob, set: [updated_at: timestamp, status: "validating"])
        assert MetadataUpdateJobs.reset_stalled(360) == {:ok, 0, 1}
        assert %{status: status, retries: retries} = MetadataUpdateJob |> Repo.one()
        assert status == "pending"
        assert retries == 1

        Repo.update_all(MetadataUpdateJob, set: [updated_at: timestamp, status: "processing"])
        assert MetadataUpdateJobs.reset_stalled(360) == {:ok, 0, 1}
        assert %{status: status, retries: retries} = MetadataUpdateJob |> Repo.one()
        assert status == "valid"
        assert retries == 2

        Repo.update_all(MetadataUpdateJob,
          set: [updated_at: timestamp, status: "validating", retries: 3]
        )

        assert MetadataUpdateJobs.reset_stalled(360) == {:ok, 1, 0}
        assert %{status: status, errors: errors} = MetadataUpdateJob |> Repo.one()
        assert status == "error"

        assert errors == [
                 %{"errors" => %{"status" => ["Stuck in validating after 3 retries"]}, "row" => 0}
               ]
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
    @describetag source: "test/fixtures/csv/sheets/bad_headers.csv"

    test "apply_job/1", %{create_result: result} do
      assert {:ok, job} = result
      assert {:error, "validation", %{errors: errors}} = MetadataUpdateJobs.apply_job(job)

      assert errors == [
               %{errors: %{published: ["is missing"], publishedd: ["is unknown"]}, row: 1}
             ]
    end
  end

  describe "missing headers" do
    @describetag source: "test/fixtures/csv/sheets/missing_headers.csv"

    test "apply_job/1", %{create_result: result} do
      assert {:ok, job} = result
      assert {:error, "validation", %{errors: errors}} = MetadataUpdateJobs.apply_job(job)

      assert errors == [
               %{errors: %{headers: ["could not identify header row"]}, row: 1}
             ]
    end
  end

  describe "query row flexibility" do
    @tag source: "test/fixtures/csv/sheets/extra_query_rows.csv"

    test "apply_job/1 with extra query rows", %{create_result: {:ok, job}} do
      assert {:ok, %{status: "complete"}} = MetadataUpdateJobs.apply_job(job)
    end

    @tag source: "test/fixtures/csv/sheets/missing_query_row.csv"
    test "apply_job/1 with no query row", %{create_result: {:ok, job}} do
      assert {:ok, %{status: "complete"}} = MetadataUpdateJobs.apply_job(job)
    end
  end

  describe "coded term validation" do
    @describetag source: "test/fixtures/csv/sheets/invalid_coded_term.csv"
    test "apply_job/1", %{create_result: result} do
      assert {:ok, job} = result
      assert {:error, "validation", %{errors: errors}} = MetadataUpdateJobs.apply_job(job)
      refute MetadataUpdateJobs.get_job(job.id) |> Map.get(:active)

      assert errors == [
               %{
                 errors: %{
                   "subject#1" => [
                     "METAPHORICAL is an invalid coded term for scheme SUBJECT_ROLE"
                   ]
                 },
                 row: 15
               }
             ]
    end
  end

  describe "controlled terms preflight failure" do
    @describetag source: "test/fixtures/csv/sheets/invalid_terms.csv"

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

  describe "bad subjects" do
    @describetag source: "test/fixtures/csv/sheets/bad_subjects.csv"

    test "apply_job/1", %{create_result: result} do
      assert {:ok, job} = result
      assert {:error, "validation", %{errors: errors}} = MetadataUpdateJobs.apply_job(job)
      refute MetadataUpdateJobs.get_job(job.id) |> Map.get(:active)

      assert errors == [
               %{
                 errors: %{
                   "GEOGRAPHICAL:bad subject" => "is from an unknown authority",
                   "unqualified bad subject" => "is from an unknown authority"
                 },
                 row: 0
               }
             ]
    end
  end

  describe "invalid data" do
    @describetag source: "test/fixtures/csv/sheets/invalid.csv"

    test "apply_job/1", %{create_result: result} do
      assert {:ok, job} = result
      assert {:error, "validation", %{errors: errors}} = MetadataUpdateJobs.apply_job(job)
      refute MetadataUpdateJobs.get_job(job.id) |> Map.get(:active)

      assert errors == [
               %{errors: %{"notes" => ["cannot have a blank id"]}, row: 10},
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
               %{errors: %{"subject#3" => ["can't be blank"]}, row: 21},
               %{errors: %{"reading_room" => "tire is invalid"}, row: 24},
               %{errors: %{"published" => "flase is invalid"}, row: 26},
               %{errors: %{"id" => "is required"}, row: 28},
               %{errors: %{"accession_number" => "MISMATCHED_ACCESSION does not match"}, row: 37}
             ]
    end
  end
end
