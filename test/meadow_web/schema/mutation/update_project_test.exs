defmodule MeadowWeb.Schema.Mutation.UpdateProjectTest do
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

      title = get_in(query_data, [:data, "updateProject", "title"])
      assert title == "The New Title"
    end
  end
end
