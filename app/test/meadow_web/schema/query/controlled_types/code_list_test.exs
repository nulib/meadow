defmodule MeadowWeb.Schema.Query.CodeListTest do
  use Meadow.DataCase
  use MeadowWeb.ConnCase, async: true
  use Wormwood.GQLCase

  load_gql(MeadowWeb.Schema, "test/gql/CodeList.gql")

  describe "codeList.gql" do
    test "retrieves a code list" do
      result = query_gql(variables: %{"scheme" => "RIGHTS_STATEMENT"}, context: gql_context())
      assert {:ok, %{data: query_data}} = result

      with result <- get_in(query_data, ["codeList"]) do
        assert length(result) == 12

        assert result
               |> Enum.member?(%{
                 "id" => "http://rightsstatements.org/vocab/InC/1.0/",
                 "label" => "In Copyright",
                 "scheme" => "RIGHTS_STATEMENT"
               })
      end
    end
  end
end
