defmodule MeadowWeb.Schema.Mutation.BatchDeleteTest do
  use Meadow.DataCase
  use Meadow.IndexCase
  use MeadowWeb.ConnCase, async: true
  use Wormwood.GQLCase
  alias Meadow.Data.Indexer

  load_gql(MeadowWeb.Schema, "test/gql/BatchDelete.gql")

  setup do
    work_fixture()

    Indexer.reindex_all()
    :ok
  end

  test "should be a valid mutation" do
    result =
      query_gql(
        variables: %{
          "query" => ~s'{"query":{"term":{"workType.id": "IMAGE"}}}',
          "nickname" => "This is a batch delete"
        },
        context: gql_context()
      )

    assert {:ok, query_data} = result

    response = get_in(query_data, [:data, "batchDelete", "status"])
    assert response =~ "QUEUED"
  end

  describe "authorization" do
    test "editors are not authorized to perform a batch delete" do
      {:ok, result} =
        query_gql(
          variables: %{
            "query" => ~s'{"query":{"term":{"workType.id": "IMAGE"}}}',
            "nickname" => "This is a batch delete"
          },
          context: %{current_user: %{username: "abc123", role: :editor}}
        )

      assert %{errors: [%{message: "Forbidden", status: 403}]} = result
    end

    test "managers and above are authorized to perform a batch delete" do
      {:ok, result} =
        query_gql(
          variables: %{
            "query" => ~s'{"query":{"term":{"workType.id": "IMAGE"}}}',
            "nickname" => "This is a batch delete"
          },
          context: %{current_user: %{username: "abc123", role: :manager}}
        )

      assert result.data["batchDelete"]
    end
  end
end
