defmodule MeadowWeb.Schema.Query.NULAuthorityRecordByIdTest do
  use Meadow.DataCase
  use MeadowWeb.ConnCase, async: true
  use Wormwood.GQLCase

  alias NUL.AuthorityRecords

  load_gql(MeadowWeb.Schema, "test/gql/GetNULAuthorityRecordById.gql")

  test "should be a valid query" do
    authority_record =
      AuthorityRecords.create_authority_record!(%{label: "test label", hint: "test hint"})

    {:ok, result} =
      query_gql(
        variables: %{"id" => authority_record.id},
        context: gql_context()
      )

    assert "test label" == get_in(result, [:data, "nulAuthorityRecord", "label"])
    assert "test hint" == get_in(result, [:data, "nulAuthorityRecord", "hint"])
  end
end
