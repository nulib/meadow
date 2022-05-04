defmodule MeadowWeb.Schema.Mutation.UpdateFileSetsTest do
  use Meadow.DataCase
  use MeadowWeb.ConnCase, async: true
  use Wormwood.GQLCase

  load_gql(MeadowWeb.Schema, "test/gql/UpdateFileSets.gql")

  test "should be a valid mutation" do
    file_set1 = file_set_fixture()
    file_set2 = file_set_fixture()

    result =
      query_gql(
        variables: %{
          "fileSets" => [
            %{"id" => file_set1.id, "coreMetadata" => %{"label" => "Something"}},
            %{"id" => file_set2.id, "coreMetadata" => %{"label" => "Something Else"}}
          ]
        },
        context: gql_context()
      )

    assert {:ok, query_data} = result

    updated_file_sets = get_in(query_data, [:data, "updateFileSets"])

    Enum.each(updated_file_sets, fn fs ->
      case get_in(fs, ["coreMetadata", "label"]) do
        "Something" ->
          assert get_in(fs, ["id"]) == file_set1.id

        _ ->
          assert get_in(fs, ["id"]) == file_set2.id
      end
    end)
  end
end
