defmodule MeadowWeb.Schema.Query.DescribeFieldsTest do
  defmodule All do
    use Meadow.DataCase
    use MeadowWeb.ConnCase, async: true
    use Wormwood.GQLCase
    load_gql(MeadowWeb.Schema, "test/gql/DescribeFields.gql")

    test "describeFields query is a valid query" do
      assert {:ok, %{data: query_data}} = query_gql(context: gql_context())
      assert length(get_in(query_data, ["describeFields"])) > 0
    end
  end

  defmodule ByID do
    use Meadow.DataCase
    use MeadowWeb.ConnCase, async: true
    use Wormwood.GQLCase
    load_gql(MeadowWeb.Schema, "test/gql/DescribeField.gql")

    test "describeField query returns field info for an id" do
      result =
        query_gql(
          variables: %{"id" => "contributor"},
          context: gql_context()
        )

      assert {:ok, query_data} = result

      assert query_data == %{
               data: %{
                 "describeField" => %{
                   "id" => "contributor",
                   "label" => "Contributor",
                   "metadataClass" => "descriptive",
                   "repeating" => true,
                   "required" => false,
                   "role" => "MARC_RELATOR",
                   "scheme" => nil
                 }
               }
             }
    end
  end
end
