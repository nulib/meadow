defmodule MeadowWeb.Schema.Mutation.CreateProjectTest do
  use Meadow.DataCase
  use MeadowWeb.ConnCase, async: true
  use Wormwood.GQLCase

  alias Meadow.Ingest.Projects

  load_gql(MeadowWeb.Schema, "test/gql/CreateProject.gql")

  test "createProject mutation creates a project" do
    result =
      query_gql(
        variables: %{"title" => "The project title"},
        context: gql_context()
      )

    assert {:ok, _query_data} = result

    project = Projects.get_project_by_title("The project title")
    assert project.title == "The project title"

    ExAws.S3.delete_object(Meadow.Config.ingest_bucket(), project.folder) |> ExAws.request()
  end

  describe "authorization" do
    test "viewers are not authorized to create projects" do
      {:ok, result} =
        query_gql(
          variables: %{"title" => "The project title"},
          context: %{current_user: %{role: :user}}
        )

      assert %{errors: [%{message: "Forbidden", status: 403}]} = result
    end

    test "editors and above are authorized to create projects" do
      {:ok, result} =
        query_gql(
          variables: %{"title" => "The project title"},
          context: %{current_user: %{role: :editor}}
        )

      assert result.data["createProject"]

      project = Projects.get_project_by_title("The project title")

      ExAws.S3.delete_object(Meadow.Config.ingest_bucket(), project.folder) |> ExAws.request()
    end
  end
end
