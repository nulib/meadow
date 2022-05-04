defmodule Meadow.Ingest.Schemas.ProjectTest do
  use Meadow.DataCase

  alias Meadow.Ingest.Projects
  alias Meadow.Ingest.Schemas.Project

  describe "projects" do
    @valid_attrs %{title: "A Sample Project"}
    @invalid_attrs %{title: nil}

    test "create_project/1 with valid data creates a project" do
      assert {:ok, %Project{} = project} = Projects.create_project(@valid_attrs)
      assert project.title == "A Sample Project"
    end

    test "create_project/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Projects.create_project(@invalid_attrs)
    end

    test "created project has a UUID identifier" do
      assert {:ok, %Project{} = project} = Projects.create_project(@valid_attrs)
      assert {:ok, <<_data::binary-size(16)>>} = Ecto.UUID.dump(project.id)
    end

    test "creating a project generates a folder name" do
      assert {:ok, %Project{} = project} = Projects.create_project(@valid_attrs)
      assert project.folder != ""
    end

    test "title must be at least four characters long" do
      attrs = %{@valid_attrs | title: "I"}
      changeset = Project.changeset(%Project{}, attrs)
      assert %{title: ["should be at least 4 character(s)"]} = errors_on(changeset)
    end

    test "title must be at most 140 characters long" do
      attrs = %{@valid_attrs | title: String.duplicate("a", 141)}
      changeset = Project.changeset(%Project{}, attrs)
      assert %{title: ["should be at most 140 character(s)"]} = errors_on(changeset)
    end
  end
end
