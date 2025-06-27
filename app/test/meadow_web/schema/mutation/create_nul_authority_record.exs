defmodule MeadowWeb.Schema.Mutation.CreateNULAuthorityRecordTest do
  use Meadow.DataCase
  use MeadowWeb.ConnCase, async: true
  use Wormwood.GQLCase

  load_gql(MeadowWeb.Schema, "test/gql/CreateNULAuthorityRecord.gql")

  test "should be a valid mutation" do
    {:ok, result} =
      query_gql(
        variables: %{"label" => "test label", "hint" => "test hint"},
        context: gql_context()
      )

    assert "test label" == get_in(result, [:data, "createNULAuthorityRecord", "label"])
    assert "test hint" == get_in(result, [:data, "createNULAuthorityRecord", "hint"])
  end

  describe "authorization" do
    test "viewers and editors are not authorized to create NUL AuthorityRecords" do
      {:ok, result} =
        query_gql(
          variables: %{"label" => "test label", "hint" => "test hint"},
          context: %{current_user: %{role: :editor}}
        )

      assert %{errors: [%{message: "Forbidden", status: 403}]} = result
    end

    test "managers and above are authorized to create NUL AuthorityRecords" do
      {:ok, result} =
        query_gql(
          variables: %{"label" => "test label", "hint" => "test hint"},
          context: %{current_user: %{role: :manager}}
        )

      assert result.data["createNULAuthorityRecord"]
    end
  end
end
