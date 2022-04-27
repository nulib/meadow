defmodule MeadowWeb.Schema.Mutation.DeleteNULAuthorityRecordTest do
  use Meadow.DataCase
  use MeadowWeb.ConnCase, async: true
  use Wormwood.GQLCase

  alias NUL.AuthorityRecords

  load_gql(MeadowWeb.Schema, "test/gql/DeleteNULAuthorityRecord.gql")

  setup do
    {:ok, authority_record: AuthorityRecords.create_authority_record!(%{label: "test label"})}
  end

  test "should be a valid mutation", %{authority_record: authority_record} do
    {:ok, _result} =
      query_gql(
        variables: %{
          "nulAuthorityRecordId" => authority_record.id
        },
        context: gql_context()
      )

    assert Enum.empty?(AuthorityRecords.list_authority_records())
  end
end
