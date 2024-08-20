defmodule MeadowWeb.Schema.Query.ProjectsTest do
  defmodule All do
    use Meadow.DataCase
    use MeadowWeb.ConnCase, async: true
    use Wormwood.GQLCase

    set_gql(MeadowWeb.Schema, """
    query($query: String!) {
      projectsSearch(query: $query){
        title
      }
    }
    """)

    test "projects search is a valid query" do
      projects_fixture()

      result =
        query_gql(
          variables: %{"query" => "Project"},
          context: gql_context()
        )

      assert {:ok, query_data} = result

      projects = get_in(query_data, [:data, "projectsSearch"])
      assert length(projects) == 3
    end
  end

  defmodule Search do
    use Meadow.DataCase
    use MeadowWeb.ConnCase, async: true
    use Wormwood.GQLCase

    set_gql(MeadowWeb.Schema, """
    query($query: String!) {
      projectsSearch(query: $query){
        title
      }
    }
    """)

    test "search project title with query string" do
      projects_fixture()

      result =
        query_gql(
          variables: %{"query" => "2"},
          context: gql_context()
        )

      assert {:ok, query_data} = result

      projects = get_in(query_data, [:data, "projectsSearch"])
      assert length(projects) == 1
    end
  end
end
