defmodule MeadowWeb.Schema.Mutation.DeleteFileSetTest do
  use Meadow.DataCase
  use MeadowWeb.ConnCase, async: true
  use Wormwood.GQLCase

  alias Meadow.Data.FileSets

  load_gql(MeadowWeb.Schema, "test/gql/DeleteFileSet.gql")

  test "should be a valid mutation" do
    file_set = file_set_fixture()

    result =
      query_gql(
        variables: %{"fileSetId" => file_set.id},
        context: gql_context()
      )

    assert {:ok, _query_data} = result
    assert Enum.empty?(FileSets.list_file_sets())
  end
end
