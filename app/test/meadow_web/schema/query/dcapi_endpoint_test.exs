defmodule MeadowWeb.Schema.Query.DcapiEndpointTest do
  use Meadow.DataCase
  use MeadowWeb.ConnCase, async: true
  use Wormwood.GQLCase

  set_gql(
    MeadowWeb.Schema,
    """
    query {
      dcapiEndpoint {
        url
      }
    }
    """
  )

  test "should return environment specific DC API endpoint" do
    assert {:ok, %{data: data}} =
             query_gql(
               variables: %{},
               context: gql_context()
             )

    assert "http://dcapi-test.northwestern.edu" = get_in(data, ["dcapiEndpoint", "url"])
  end
end
