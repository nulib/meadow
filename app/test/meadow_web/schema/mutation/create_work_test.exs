defmodule MeadowWeb.Schema.Mutation.CreateWorkTest do
  use Meadow.AuthorityCase
  use Meadow.DataCase
  use MeadowWeb.ConnCase, async: true
  use Wormwood.GQLCase

  load_gql(MeadowWeb.Schema, "test/gql/CreateWork.gql")

  describe "CreateWork mutation" do
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
                  "term" => "mock1:result1",
                  "role" => %{"id" => "aut", "scheme" => "MARC_RELATOR"}
                }
              ],
              "stylePeriod" => [
                %{
                  "term" => "mock1:result1"
                }
              ]
            },
            "administrativeMetadata" => %{},
            "workType" => %{"id" => "IMAGE", "scheme" => "WORK_TYPE"},
            "visibility" => %{"id" => "OPEN", "scheme" => "VISIBILITY"}
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

  describe "authorization" do
    test "viewers are not authorized to create shared links" do
      {:ok, result} =
        query_gql(
          variables: %{
            "accessionNumber" => "12345.abc",
            "published" => false,
            "descriptiveMetadata" => %{},
            "administrativeMetadata" => %{},
            "workType" => %{"id" => "IMAGE", "scheme" => "WORK_TYPE"},
            "visibility" => %{"id" => "OPEN", "scheme" => "VISIBILITY"}
          },
          context: %{current_user: %{role: "User"}}
        )

      assert %{errors: [%{message: "Forbidden", status: 403}]} = result
    end

    test "editors and above are authorized to create shared links" do
      {:ok, result} =
        query_gql(
          variables: %{
            "accessionNumber" => "12345.abc",
            "published" => false,
            "descriptiveMetadata" => %{},
            "administrativeMetadata" => %{},
            "workType" => %{"id" => "IMAGE", "scheme" => "WORK_TYPE"},
            "visibility" => %{"id" => "OPEN", "scheme" => "VISIBILITY"}
          },
          context: %{current_user: %{role: "Editor"}}
        )

      assert result.data["createWork"]
    end
  end
end
