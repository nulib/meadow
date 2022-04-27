defmodule MeadowWeb.Schema.Query.FileSetsTest do
  use Meadow.DataCase
  use MeadowWeb.ConnCase, async: true

  @query """
  query {
    fileSets{
      id
    }
  }
  """

  test "fileSets query returns all file_sets" do
    file_set_fixture()
    file_set_fixture()
    file_set_fixture()

    conn = build_conn() |> auth_user(user_fixture())

    response = get(conn, "/api/graphql", query: @query)

    assert %{
             "data" => %{
               "fileSets" => [
                 %{"id" => _},
                 %{"id" => _},
                 %{"id" => _}
               ]
             }
           } = json_response(response, 200)
  end

  @delete_query """
  mutation ($file_set_id: ID!) {
    deleteFileSet(fileSetId: $file_set_id){
      id
    }
  }
  """

  test "delete file_set mutation deletes a file set" do
    file_set = file_set_fixture()

    input = %{
      "file_set_id" => file_set.id
    }

    conn = build_conn() |> auth_user(user_fixture())

    response = post(conn, "/api/graphql", query: @delete_query, variables: input)

    assert %{
             "data" => %{
               "deleteFileSet" => %{"id" => file_set.id}
             }
           } == json_response(response, 200)
  end
end
