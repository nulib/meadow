defmodule MeadowWeb.Schema.Mutation.CreateWorkTest do
  use MeadowWeb.ConnCase, async: true
  use Wormwood.GQLCase

  alias Authoritex.Mock

  load_gql(MeadowWeb.Schema, "test/gql/CreateWork.gql")

  describe "CreateWork mutation" do
    @data [
      %{
        id: "mock:result1",
        label: "First Result",
        qualified_label: "First Result (1)",
        hint: "(1)"
      }
    ]

    setup do
      Mock.set_data(@data)
      :ok
    end

    test "should be a valid mutation" do
      result =
        query_gql(
          variables: %{
            "accessionNumber" => "12345.abc",
            "published" => false,
            "descriptiveMetadata" => %{
              "title" => "Something",
              "contributor" => [
                %{
                  "term" => "mock:result1",
                  "role" => %{"id" => "aut", "scheme" => "MARC_RELATOR"}
                }
              ],
              "stylePeriod" => [
                %{
                  "term" => "mock:result1"
                }
              ]
            },
            "administrativeMetadata" => %{},
            "workType" => %{"id" => "IMAGE"},
            "visibility" => %{"id" => "OPEN"}
          },
          context: gql_context()
        )

      assert {:ok, query_data} = result

      assert "Something" ==
               get_in(query_data, [:data, "createWork", "descriptiveMetadata", "title"])

      contributor =
        query_data
        |> get_in([:data, "createWork", "descriptiveMetadata", "contributor"])
        |> List.first()

      assert contributor |> get_in(["term", "label"]) == "First Result"
      assert contributor |> get_in(["role", "label"]) == "Author"

      style_period =
        query_data
        |> get_in([:data, "createWork", "descriptiveMetadata", "stylePeriod"])
        |> List.first()

      assert is_nil(style_period |> get_in(["role"]))
    end
  end
end
