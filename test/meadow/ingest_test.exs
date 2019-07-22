defmodule Meadow.IngestTest do
  use Meadow.DataCase

  alias Meadow.Ingest

  describe "projects" do
    alias Meadow.Ingest.Project

    @valid_attrs %{title: "some title"}
    @update_attrs %{title: "some updated title"}
    @invalid_attrs %{title: nil}

    def project_fixture(attrs \\ %{}) do
      {:ok, project} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Ingest.create_project()

      project
    end

    test "list_projects/0 returns all projects" do
      project = project_fixture()
      assert Ingest.list_projects() == [project]
    end

    test "get_project!/1 returns the project with given id" do
      project = project_fixture()
      assert Ingest.get_project!(project.id) == project
    end

    test "create_project/1 with valid data creates a project" do
      assert {:ok, %Project{} = project} = Ingest.create_project(@valid_attrs)
      assert project.title == "some title"
      assert project.folder != ""
    end

    test "create_project/1 with valid data generates a folder name" do
      assert {:ok, %Project{} = project} = Ingest.create_project(@valid_attrs)
      assert project.folder != ""
    end

    test "create_project/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Ingest.create_project(@invalid_attrs)
    end

    test "update_project/2 with valid data updates the project" do
      project = project_fixture()
      assert {:ok, %Project{} = project} = Ingest.update_project(project, @update_attrs)
      assert project.title == "some updated title"
    end

    test "update_project/2 with valid data does not change the orignal folder name" do
      project = project_fixture()
      original_folder_name = project.folder
      assert {:ok, %Project{} = project} = Ingest.update_project(project, @update_attrs)
      assert project.folder == original_folder_name
    end

    test "update_project/2 with invalid data returns error changeset" do
      project = project_fixture()
      assert {:error, %Ecto.Changeset{}} = Ingest.update_project(project, @invalid_attrs)
      assert project == Ingest.get_project!(project.id)
    end

    test "delete_project/1 deletes the project" do
      project = project_fixture()
      assert {:ok, %Project{}} = Ingest.delete_project(project)
      assert_raise Ecto.NoResultsError, fn -> Ingest.get_project!(project.id) end
    end

    test "change_project/1 returns a project changeset" do
      project = project_fixture()
      assert %Ecto.Changeset{} = Ingest.change_project(project)
    end
  end

  describe "ingest_jobs" do
    alias Meadow.Ingest.IngestJob

    @valid_attrs %{
      name: "some name",
      presigned_url: "some presigned_url",
      filename: "some_name.csv",
      project_id: "01DFC45C20ZMBD1R57HWTSKJ1N"
    }
    @update_attrs %{
      name: "some updated name",
      presigned_url: "some updated presigned_url",
      filename: "some_name.csv",
      project_id: "01DFC45C20ZMBD1R57HWTSKJ1N"
    }
    @invalid_attrs %{name: nil, presigned_url: nil, filename: nil}

    def ingest_job_fixture(attrs \\ %{}) do
      {:ok, ingest_job} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Ingest.create_ingest_job()

      ingest_job
    end

    test "list_ingest_jobs/0 returns all ingest_jobs" do
      project = project_fixture()
      ingest_job = ingest_job_fixture(Map.put(@valid_attrs, :project_id, project.id))
      assert Ingest.list_ingest_jobs() == [ingest_job]
    end

    test "get_ingest_job!/1 returns the job with given id" do
      project = project_fixture()
      ingest_job = ingest_job_fixture(Map.put(@valid_attrs, :project_id, project.id))
      assert Ingest.get_ingest_job!(ingest_job.id) == ingest_job
    end

    test "create_ingest_job/1 with valid data creates a job" do
      project = project_fixture()

      assert {:ok, %IngestJob{} = ingest_job} =
               Ingest.create_ingest_job(Map.put(@valid_attrs, :project_id, project.id))

      assert ingest_job.name == "some name"
      assert ingest_job.presigned_url == "some presigned_url"
    end

    test "create_ingest_job/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Ingest.create_ingest_job(@invalid_attrs)
    end

    test "update_ingest_job/2 with valid data updates the ingest job" do
      project = project_fixture()
      ingest_job = ingest_job_fixture(Map.put(@valid_attrs, :project_id, project.id))

      assert {:ok, %IngestJob{} = ingest_job} =
               Ingest.update_ingest_job(
                 ingest_job,
                 Map.put(@update_attrs, :project_id, project.id)
               )

      assert ingest_job.name == "some updated name"
      assert ingest_job.presigned_url == "some updated presigned_url"
    end

    test "update_ingest_job/2 with invalid data returns error changeset" do
      project = project_fixture()
      ingest_job = ingest_job_fixture(Map.put(@valid_attrs, :project_id, project.id))

      assert {:error, %Ecto.Changeset{}} =
               Ingest.update_ingest_job(
                 ingest_job,
                 Map.put(@invalid_attrs, :project_id, project.id)
               )

      assert ingest_job == Ingest.get_ingest_job!(ingest_job.id)
    end

    test "delete_ingest_job/1 deletes the job" do
      project = project_fixture()
      ingest_job = ingest_job_fixture(Map.put(@valid_attrs, :project_id, project.id))
      assert {:ok, %IngestJob{}} = Ingest.delete_ingest_job(ingest_job)
      assert_raise Ecto.NoResultsError, fn -> Ingest.get_ingest_job!(ingest_job.id) end
    end

    test "change_job/1 returns a job changeset" do
      project = project_fixture()
      ingest_job = ingest_job_fixture(Map.put(@valid_attrs, :project_id, project.id))
      assert %Ecto.Changeset{} = Ingest.change_ingest_job(ingest_job)
    end
  end
end
