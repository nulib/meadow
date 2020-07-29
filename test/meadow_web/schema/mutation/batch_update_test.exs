defmodule MeadowWeb.Schema.Mutation.BatchUpdateTest do
  use MeadowWeb.ConnCase, async: true
  use Wormwood.GQLCase

  load_gql(MeadowWeb.Schema, "test/gql/BatchUpdate.gql")

  test "should be a valid mutation" do
    result =
      query_gql(
        variables: %{
          "query" => "{\"based_near.label.keyword\": \"England--London\"}",
          "delete" => %{
            "contributor" => [
              %{
                "term" => "http => //reemoveme",
                "role" => %{"id" => "aut", "scheme" => "MARC_RELATOR"}
              }
            ]
          }
        },
        context: gql_context()
      )

    assert {:ok, query_data} = result

    response = get_in(query_data, [:data, "batchUpdate", "message"])
    assert response == "Batch started"
  end
end
