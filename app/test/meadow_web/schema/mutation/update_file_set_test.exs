defmodule MeadowWeb.Schema.Mutation.UpdateFileSetTest do
  use Meadow.DataCase
  use MeadowWeb.ConnCase, async: true
  use Wormwood.GQLCase

  load_gql(MeadowWeb.Schema, "test/gql/UpdateFileSet.gql")

  test "should be a valid mutation" do
    file_set = file_set_fixture()

    result =
      query_gql(
        variables: %{
          "id" => file_set.id,
          "coreMetadata" => %{"label" => "Something"}
        },
        context: gql_context()
      )

    assert {:ok, query_data} = result

    label = get_in(query_data, [:data, "updateFileSet", "coreMetadata", "label"])
    assert label == "Something"
  end
end
