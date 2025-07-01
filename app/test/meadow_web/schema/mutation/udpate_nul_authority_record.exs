defmodule MeadowWeb.Schema.Mutation.UpdateNULAuthorityRecordTest do
  use Meadow.DataCase
  use MeadowWeb.ConnCase, async: true
  use Wormwood.GQLCase

  alias NUL.AuthorityRecords

  load_gql(MeadowWeb.Schema, "test/gql/UpdateNULAuthorityRecord.gql")

  test "should be a valid mutation" do
    authority_record =
      AuthorityRecords.create_authority_record!(%{label: "test label", hint: "test hint"})

    {:ok, result} =
      query_gql(
        variables: %{
          "id" => authority_record.id,
          "label" => "new test label",
          "hint" => "new test hint"
        },
        context: gql_context()
      )

    assert "new test label" == get_in(result, [:data, "updateNULAuthorityRecord", "label"])
    assert "new test hint" == get_in(result, [:data, "updateNULAuthorityRecord", "hint"])
  end

  describe "authorization" do
    test "viewers and editors are not authorized to update NUL AuthorityRecords" do
      authority_record =
        AuthorityRecords.create_authority_record!(%{label: "test label", hint: "test hint"})

      {:ok, result} =
        query_gql(
          variables: %{
            "id" => authority_record.id,
            "label" => "test label",
            "hint" => "test hint"
          },
          context: %{current_user: %{role: :editor}}
        )

      assert %{errors: [%{message: "Forbidden", status: 403}]} = result
    end

    test "managers and above are authorized to update NUL AuthorityRecords" do
      authority_record =
        AuthorityRecords.create_authority_record!(%{label: "test label", hint: "test hint"})

      {:ok, result} =
        query_gql(
          variables: %{
            "id" => authority_record.id,
            "label" => "test label",
            "hint" => "test hint"
          },
          context: %{current_user: %{role: :manager}}
        )

      assert result.data["updateNULAuthorityRecord"]
    end
  end
end
