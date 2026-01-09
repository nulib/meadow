defmodule Meadow.GeoNamesHttpMock do
  @moduledoc """
  HTTP mock for GeoNames API using Req.Test
  """

  @doc """
  Sets up Req.Test stub for GeoNames API requests.
  Call this in your test setup to mock GeoNames HTTP responses.
  """
  def setup_geonames_stub do
    Req.Test.stub(Meadow.GeoNamesHttpMock, &handle_request/1)
  end

  defp handle_request(conn) do
    # Only intercept GeoNames API requests
    if conn.host == "api.geonames.org" do
      handle_geonames_request(conn)
    else
      # Pass through other requests
      conn
    end
  end

  defp handle_geonames_request(conn) do
    # Extract geonameId from query params
    geoname_id = conn.query_params["geonameId"]

    case geoname_id do
      "4887398" ->
        Req.Test.json(conn, %{
          "geonameId" => 4_887_398,
          "name" => "Chicago",
          "lat" => 41.85003,
          "lng" => -87.65005,
          "countryName" => "United States",
          "adminName1" => "Illinois"
        })

      "2110435" ->
        Req.Test.json(conn, %{
          "geonameId" => 2_110_435,
          "name" => "Ewa District",
          "lat" => -0.5033,
          "lng" => 166.93453,
          "countryName" => "Nauru",
          "adminName1" => "Ewa District"
        })

      _ ->
        Req.Test.json(conn, %{"status" => %{"message" => "record does not exist", "value" => 11}})
    end
  end
end
