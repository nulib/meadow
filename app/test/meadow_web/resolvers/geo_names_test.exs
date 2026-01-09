defmodule MeadowWeb.Resolvers.Data.GeoNamesTest do
  use Meadow.DataCase
  use MeadowWeb.ConnCase, async: true
  use Meadow.AuthorityCase
  use Meadow.GeoNamesCase
  use Wormwood.GQLCase

  load_gql(MeadowWeb.Schema, "test/gql/GeonamesPlace.gql")

  import Meadow.TestHelpers

  describe "geonames place resolver" do
    test "fetches place data for Chicago by geoname ID" do
      result =
        query_gql(
          variables: %{"id" => "4887398"},
          context: gql_context()
        )

      assert {:ok, %{data: query_data}} = result
      place = query_data["geonamesPlace"]

      assert place["type"] == "Feature"
      assert place["id"] == "https://sws.geonames.org/4887398/"
      assert place["geometry"]["type"] == "Point"
      assert place["geometry"]["coordinates"] == [-87.65005, 41.85003]
      assert place["properties"]["label"]["en"] == ["Chicago"]
      assert place["properties"]["summary"]["en"] == ["Illinois, United States"]
    end

    test "fetches place data for Ewa District by geoname ID" do
      result =
        query_gql(
          variables: %{"id" => "2110435"},
          context: gql_context()
        )

      assert {:ok, %{data: query_data}} = result
      place = query_data["geonamesPlace"]

      assert place["type"] == "Feature"
      assert place["id"] == "https://sws.geonames.org/2110435/"
      assert place["geometry"]["type"] == "Point"
      assert place["geometry"]["coordinates"] == [166.93453, -0.5033]
      assert place["properties"]["label"]["en"] == ["Ewa District"]
      assert place["properties"]["summary"]["en"] == ["Ewa District, Nauru"]
    end

    test "fetches place data by GeoNames URI" do
      result =
        query_gql(
          variables: %{"id" => "https://sws.geonames.org/4887398/"},
          context: gql_context()
        )

      assert {:ok, %{data: query_data}} = result
      place = query_data["geonamesPlace"]

      assert place["id"] == "https://sws.geonames.org/4887398/"
      assert place["properties"]["label"]["en"] == ["Chicago"]
    end

    test "returns error for non-existent geoname ID" do
      result =
        query_gql(
          variables: %{"id" => "9999999"},
          context: gql_context()
        )

      assert {:ok, %{data: %{"geonamesPlace" => nil}}} = result
    end
  end
end
