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
end
