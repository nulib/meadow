defmodule MeadowWeb.Schema.Query.ApiTokenTest do
  use Meadow.DataCase
  use MeadowWeb.ConnCase, async: true
  use Wormwood.GQLCase

  set_gql(
    MeadowWeb.Schema,
    """
    query {
      dcApiToken {
        expires
        token
      }
    }
    """
  )

  test "should return a signed API token" do
    assert {:ok, %{data: data}} =
             query_gql(
               variables: %{},
               context: gql_context()
             )

    assert {:ok, expires} =
             get_in(data, ["dcApiToken", "expires"]) |> NaiveDateTime.from_iso8601()

    assert get_in(data, ["dcApiToken", "token"]) |> is_binary()

    assert_in_delta(
      NaiveDateTime.diff(expires, NaiveDateTime.utc_now(), :second),
      300,
      2
    )
  end
end
