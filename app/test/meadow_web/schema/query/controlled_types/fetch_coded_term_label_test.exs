defmodule MeadowWeb.Schema.Query.FetchCodedTermLabelTest do
  use Meadow.DataCase
  use MeadowWeb.ConnCase, async: true
  use Wormwood.GQLCase

  load_gql(MeadowWeb.Schema, "test/gql/FetchCodedTermLabel.gql")

  describe "FetchCodedTermLabel.gql" do
    setup tags do
      {:ok,
       %{
         gql_result:
           query_gql(
             variables: %{
               "scheme" => "RIGHTS_STATEMENT",
               "id" => tags[:id]
             },
             context: gql_context()
           )
       }}
    end

    @tag id: "http://rightsstatements.org/vocab/InC/1.0/"
    test "retrieves a term", %{gql_result: result} do
      assert {:ok, %{data: query_data}} = result
      assert get_in(query_data, ["fetchCodedTermLabel", "label"]) == "In Copyright"
    end

    @tag id: "http://wrongsstatements.org/vocab/InC/1.0/"
    test "retrieves nil for a bad query", %{gql_result: result} do
      assert {:ok, %{data: query_data, errors: errors}} = result
      assert get_in(query_data, ["fetchCodedTermLabel"]) |> is_nil()

      assert get_in(List.first(errors), [:message]) ==
               "is an invalid coded term for scheme RIGHTS_STATEMENT"
    end
  end
end
