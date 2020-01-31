defmodule MeadowWeb.Schema.Query.ProjectsTest do
  use MeadowWeb.ConnCase

  @query """
  query {
    projects{
      id
      title
    }
  }
  """

  test "projects query returns all projects" do
    projects_fixture()
    conn = build_conn() |> auth_user(user_fixture())

    response = get(conn, "/api/graphql", query: @query)

    assert %{
             "data" => %{
               "projects" => [
                 %{"title" => "Project 3"},
                 %{"title" => "Project 2"},
                 %{"title" => "Project 1"}
               ]
             }
           } = json_response(response, 200)
  end

  @query """
  query($limit: Int!) {
    projects(limit: $limit){
      id
      title
    }
  }
  """
  @variables %{"limit" => 2}
  test "projects query limits the number of projects returned" do
    projects_fixture()
    conn = build_conn() |> auth_user(user_fixture())

    response = get(conn, "/api/graphql", query: @query, variables: @variables)

    assert %{
             "data" => %{
               "projects" => [
                 %{"title" => "Project 3"},
                 %{"title" => "Project 2"}
               ]
             }
           } = json_response(response, 200)
  end

  @query """
  query($order: SortOrder!) {
    projects(order: $order){
      id
      title
    }
  }
  """
  @variables %{"order" => "ASC"}
  test "projects query returns projects ascending" do
    projects_fixture()
    conn = build_conn() |> auth_user(user_fixture())

    response = get(conn, "/api/graphql", query: @query, variables: @variables)

    assert %{
             "data" => %{
               "projects" => [%{"title" => "Project 1"} | _]
             }
           } = json_response(response, 200)
  end

  @variables %{"order" => "DESC"}
  test "projects query returns projects descending" do
    projects_fixture()
    conn = build_conn() |> auth_user(user_fixture())

    response = get(conn, "/api/graphql", query: @query, variables: @variables)

    assert %{
             "data" => %{
               "projects" => [%{"title" => "Project 3"} | _]
             }
           } = json_response(response, 200)
  end
end
