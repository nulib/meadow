defmodule MeadowWeb.Schema.Query.NULAuthorityRecordsTest do
  use Meadow.DataCase
  use MeadowWeb.ConnCase, async: true
  use Wormwood.GQLCase

  alias NUL.AuthorityRecords

  load_gql(MeadowWeb.Schema, "test/gql/GetNULAuthorityRecords.gql")

  test "should be a valid query" do
    AuthorityRecords.create_authority_record!(%{label: "one"})
    AuthorityRecords.create_authority_record!(%{label: "two"})
    AuthorityRecords.create_authority_record!(%{label: "three"})

    {:ok, result} =
      query_gql(
        variables: %{"limit" => 2},
        context: gql_context()
      )

    nul_authority_records = get_in(result, [:data, "nulAuthorityRecords"])
    assert length(nul_authority_records) == 2
  end
end
