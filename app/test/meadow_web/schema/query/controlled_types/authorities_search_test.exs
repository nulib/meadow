defmodule MeadowWeb.Schema.Query.AuthoritiesSearchTest do
  use Meadow.AuthorityCase
  use Meadow.DataCase
  use MeadowWeb.ConnCase, async: true
  use Wormwood.GQLCase

  alias NUL.Schemas.AuthorityRecord

  load_gql(MeadowWeb.Schema, "test/gql/AuthoritiesSearch.gql")

  describe "AuthoritiesSearch.gql" do
    test "Is a valid query" do
      result =
        query_gql(variables: %{"authority" => "mock", "query" => "test"}, context: gql_context())

      assert {:ok, %{data: query_data}} = result

      with result <- get_in(query_data, ["authoritiesSearch"]) do
        assert result
               |> Enum.member?(%{
                 "id" => "mock1:result2",
                 "label" => "Second Result",
                 "hint" => "(2)"
               })
      end
    end
  end

  describe "NUL Authorities" do
    @describetag shared: true

    setup do
      record = %{
        id: "info:nul/b9a963ed-afa3-4f95-b3fd-ed440a974d76",
        label: "Harrison and Abramovitz (American architectural firm, 1945-1976)",
        hint: nil
      }

      Ecto.Changeset.change(%AuthorityRecord{}, record)
      |> Meadow.Repo.insert()

      {:ok, record}
    end

    test "Finds a NUL authority record by regular search" do
      result =
        query_gql(
          variables: %{
            "authority" => "nul-authority",
            "query" => "Abram"
          },
          context: gql_context()
        )

      assert {:ok, %{data: query_data}} = result

      with [result | _] <- get_in(query_data, ["authoritiesSearch"]) do
        assert result == %{
                 "id" => "info:nul/b9a963ed-afa3-4f95-b3fd-ed440a974d76",
                 "label" => "Harrison and Abramovitz (American architectural firm, 1945-1976)",
                 "hint" => nil
               }
      end
    end

    test "Finds a NUL authority record by URI" do
      result =
        query_gql(
          variables: %{
            "authority" => "nul-authority",
            "query" => "info:nul/b9a963ed-afa3-4f95-b3fd-ed440a974d76"
          },
          context: gql_context()
        )

      assert {:ok, %{data: query_data}} = result

      with [result | _] <- get_in(query_data, ["authoritiesSearch"]) do
        assert result == %{
                 "id" => "info:nul/b9a963ed-afa3-4f95-b3fd-ed440a974d76",
                 "label" => "Harrison and Abramovitz (American architectural firm, 1945-1976)",
                 "hint" => nil
               }
      end
    end
  end
end
