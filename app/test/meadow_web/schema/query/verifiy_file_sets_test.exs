defmodule MeadowWeb.Schema.Query.VerifyFileSets do
  use Meadow.DataCase
  use MeadowWeb.ConnCase, async: true
  use Wormwood.GQLCase

  load_gql(MeadowWeb.Schema, "test/gql/VerifyFileSets.gql")

  test "should be a valid query" do
    work = work_with_file_sets_fixture(1)

    result =
      query_gql(
        variables: %{"workId" => work.id},
        context: gql_context()
      )

    assert {:ok, query_data} = result

    file_sets = get_in(query_data, [:data, "verifyFileSets"])
    assert get_in(List.first(file_sets), ["fileSetId"]) == List.first(work.file_sets).id
    assert get_in(List.first(file_sets), ["verified"]) == false
  end
end
