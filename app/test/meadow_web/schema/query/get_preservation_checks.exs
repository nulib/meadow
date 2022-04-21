defmodule MeadowWeb.Schema.Query.PreservationChecksTest do
  use Meadow.DataCase
  use MeadowWeb.ConnCase, async: true
  use Wormwood.GQLCase

  alias Meadow.Data.PreservationChecks

  load_gql(MeadowWeb.Schema, "test/gql/GetPreservationChecks.gql")

  test "should be a valid query" do
    PreservationChecks.create_job(%{})
    PreservationChecks.create_job(%{})
    PreservationChecks.create_job(%{})

    result =
      query_gql(
        variables: %{},
        context: gql_context()
      )

    assert {:ok, query_data} = result

    preservation_checks = get_in(query_data, [:data, "preservationChecks"])
    assert length(preservation_checks) == 3
  end
end
