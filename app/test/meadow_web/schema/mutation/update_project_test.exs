defmodule MeadowWeb.Schema.Mutation.UpdateProjectTest do
  use Meadow.DataCase
  use MeadowWeb.ConnCase, async: true
  use Wormwood.GQLCase

  load_gql(MeadowWeb.Schema, "test/gql/UpdateProject.gql")

  describe "updateProject mutation" do
    test "should allow the title to be updated" do
      project = project_fixture()

      result =
        query_gql(
          variables: %{
            "id" => project.id,
            "title" => "The New Title"
          },
          context: gql_context()
        )

      assert {:ok, query_data} = result

      assert project.id == get_in(query_data, [:data, "updateProject", "id"])
      assert "The New Title" == get_in(query_data, [:data, "updateProject", "title"])
    end
  end

  describe "authorization" do
    test "viewers are not authorized to update projects" do
      project = project_fixture()

      {:ok, result} =
        query_gql(
          variables: %{
            "id" => project.id,
            "title" => "The New Title"
          },
          context: gql_context(%{role: :user})
        )

      assert %{errors: [%{message: "Forbidden", status: 403}]} = result
    end

    test "editors and above are authorized to update projects" do
      project = project_fixture()

      {:ok, result} =
        query_gql(
          variables: %{
            "id" => project.id,
            "title" => "The New Title"
          },
          context: gql_context(%{role: :editor})
        )

      assert result.data["updateProject"]
    end
  end
end
