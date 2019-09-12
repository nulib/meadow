defmodule Meadow.Ingest.IngestJobsTest do
  use Meadow.DataCase

  alias Meadow.Ingest.IngestJobs
  alias Meadow.Ingest.IngestJobs.IngestJob

  describe "ingest_jobs" do
    @valid_attrs %{
      name: "some name",
      filename: "some_name.csv",
      project_id: "01DFC45C20ZMBD1R57HWTSKJ1N"
    }
    @update_attrs %{
      name: "some updated name",
      filename: "some_name.csv",
      project_id: "01DFC45C20ZMBD1R57HWTSKJ1N"
    }
    @invalid_attrs %{name: nil, filename: nil}

    test "list_ingest_jobs/0 returns all ingest_jobs" do
      project = project_fixture()
      ingest_job = ingest_job_fixture(Map.put(@valid_attrs, :project_id, project.id))
      assert IngestJobs.list_ingest_jobs(project) == [ingest_job]
    end

    test "get_ingest_job!/1 returns the job with given id" do
      project = project_fixture()
      ingest_job = ingest_job_fixture(Map.put(@valid_attrs, :project_id, project.id))
      assert IngestJobs.get_ingest_job!(ingest_job.id) == ingest_job
    end

    test "create_ingest_job/1 with valid data creates a job" do
      project = project_fixture()

      assert {:ok, %IngestJob{} = ingest_job} =
               IngestJobs.create_ingest_job(Map.put(@valid_attrs, :project_id, project.id))

      assert ingest_job.name == "some name"
    end

    test "create_ingest_job/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = IngestJobs.create_ingest_job(@invalid_attrs)
    end

    test "update_ingest_job/2 with valid data updates the ingest job" do
      project = project_fixture()
      ingest_job = ingest_job_fixture(Map.put(@valid_attrs, :project_id, project.id))

      assert {:ok, %IngestJob{} = ingest_job} =
               IngestJobs.update_ingest_job(
                 ingest_job,
                 Map.put(@update_attrs, :project_id, project.id)
               )

      assert ingest_job.name == "some updated name"
    end

    test "update_ingest_job/2 with invalid data returns error changeset" do
      project = project_fixture()
      ingest_job = ingest_job_fixture(Map.put(@valid_attrs, :project_id, project.id))

      assert {:error, %Ecto.Changeset{}} =
               IngestJobs.update_ingest_job(
                 ingest_job,
                 Map.put(@invalid_attrs, :project_id, project.id)
               )

      assert ingest_job == IngestJobs.get_ingest_job!(ingest_job.id)
    end

    test "delete_ingest_job/1 deletes the job" do
      project = project_fixture()
      ingest_job = ingest_job_fixture(Map.put(@valid_attrs, :project_id, project.id))
      assert {:ok, %IngestJob{}} = IngestJobs.delete_ingest_job(ingest_job)

      assert_raise Ecto.NoResultsError, fn ->
        IngestJobs.get_ingest_job!(ingest_job.id)
      end
    end

    test "change_job/1 returns a job changeset" do
      project = project_fixture()
      ingest_job = ingest_job_fixture(Map.put(@valid_attrs, :project_id, project.id))
      assert %Ecto.Changeset{} = IngestJobs.change_ingest_job(ingest_job)
    end
  end
end
