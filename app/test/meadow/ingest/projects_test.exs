defmodule Meadow.Ingest.ProjectsTest do
  use Meadow.DataCase

  alias Meadow.Ingest.Projects
  alias Meadow.Ingest.Schemas.Project

  describe "projects" do
    @valid_attrs %{title: "some title"}
    @update_attrs %{title: "some updated title"}
    @invalid_attrs %{title: nil}

    test "list_projects/0 returns all projects" do
      project = project_fixture(@valid_attrs)
      assert Projects.list_projects() == [project]
    end

    test "projects_search/0 returns list of matched projects" do
      project = project_fixture(@valid_attrs)
      assert Projects.search("some title") == [project]
      assert Projects.search("nothing") == []
    end

    test "get_project!/1 returns the project with given id" do
      project = project_fixture(@valid_attrs)
      assert Projects.get_project!(project.id) == project
    end

    test "create_project/1 with valid data creates a project" do
      assert {:ok, %Project{} = project} = Projects.create_project(@valid_attrs)
      assert project.title == "some title"
      assert project.folder != ""
    end

    test "create_project/1 with valid data generates a folder name" do
      assert {:ok, %Project{} = project} = Projects.create_project(@valid_attrs)
      assert project.folder != ""
    end

    test "create_project/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Projects.create_project(@invalid_attrs)
    end

    test "update_project/2 with valid data updates the project" do
      project = project_fixture(@valid_attrs)
      assert {:ok, %Project{} = project} = Projects.update_project(project, @update_attrs)
      assert project.title == "some updated title"
    end

    test "update_project/2 with valid data does not change the orignal folder name" do
      project = project_fixture(@valid_attrs)
      original_folder_name = project.folder
      assert {:ok, %Project{} = project} = Projects.update_project(project, @update_attrs)
      assert project.folder == original_folder_name
    end

    test "update_project/2 with invalid data returns error changeset" do
      project = project_fixture(@valid_attrs)
      assert {:error, %Ecto.Changeset{}} = Projects.update_project(project, @invalid_attrs)
      assert project == Projects.get_project!(project.id)
    end

    test "delete_project/1 deletes the project" do
      project = project_fixture(@valid_attrs)
      assert {:ok, %Project{}} = Projects.delete_project(project)
      assert_raise Ecto.NoResultsError, fn -> Projects.get_project!(project.id) end
    end

    test "change_project/1 returns a project changeset" do
      project = project_fixture()
      assert %Ecto.Changeset{} = Projects.change_project(project)
    end
  end
end
