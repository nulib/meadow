defmodule MeadowWeb.Schema.Query.ProjectsTest do
  defmodule All do
    use Meadow.DataCase
    use MeadowWeb.ConnCase, async: true
    use Wormwood.GQLCase

    set_gql(MeadowWeb.Schema, """
    query {
      projects{
        id
        title
      }
    }
    """)

    test "projects query returns all projects" do
      projects_fixture()

      assert {:ok, %{data: query_data}} = query_gql(context: gql_context())

      assert [
               %{"title" => "Project 3"},
               %{"title" => "Project 2"},
               %{"title" => "Project 1"}
             ] = query_data["projects"]
    end
  end

  defmodule Limit do
    use Meadow.DataCase
    use MeadowWeb.ConnCase, async: true
    use Wormwood.GQLCase

    set_gql(MeadowWeb.Schema, """
    query($limit: Int) {
      projects(limit: $limit){
        id
        title
      }
    }
    """)

    @tag variables: %{"limit" => "2"}
    test "projects query limits the number of projects returned" do
      projects_fixture()

      assert {:ok, %{data: query_data}} =
               query_gql(variables: %{"limit" => 2}, context: gql_context())

      assert [
               %{"title" => "Project 3"},
               %{"title" => "Project 2"}
             ] = query_data["projects"]
    end
  end

  defmodule Order do
    use Meadow.DataCase
    use MeadowWeb.ConnCase, async: true
    use Wormwood.GQLCase

    set_gql(MeadowWeb.Schema, """
    query($order: SortOrder!) {
      projects(order: $order){
        id
        title
      }
    }
    """)

    setup tags do
      projects_fixture()
      {:ok, %{result: query_gql(variables: tags[:variables], context: gql_context())}}
    end

    @tag variables: %{"order" => "ASC"}
    test "projects query returns projects ascending", %{result: result} do
      assert {:ok, %{data: query_data}} = result
      assert [%{"title" => "Project 1"} | _] = query_data["projects"]
    end

    @tag variables: %{"order" => "DESC"}
    test "projects query returns projects descending", %{result: result} do
      assert {:ok, %{data: query_data}} = result
      assert [%{"title" => "Project 3"} | _] = query_data["projects"]
    end
  end
end
