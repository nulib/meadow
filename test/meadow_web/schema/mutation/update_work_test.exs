defmodule MeadowWeb.Schema.Mutation.UpdateWorkTest do
  use MeadowWeb.ConnCase
  use Wormwood.GQLCase

  load_gql(MeadowWeb.Schema, "assets/js/gql/UpdateWork.gql")

  test "should be a valid mutation" do
    work = work_fixture()

    result =
      query_gql(
        variables: %{
          "id" => work.id,
          "visibility" => "RESTRICTED",
          "metadata" => %{"title" => "Something"}
        },
        context: gql_context()
      )

    assert {:ok, query_data} = result

    title = get_in(query_data, [:data, "updateWork", "metadata", "title"])
    assert title == "Something"
  end
end
