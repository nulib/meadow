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

    test "Respects limit parameter in search" do
      # Create multiple authority records
      records =
        Enum.map(1..5, fn i ->
          %{
            id: "info:nul/" <> Ecto.UUID.generate(),
            label: "Test Record #{i}",
            hint: "Hint #{i}"
          }
        end)

      Enum.each(records, fn record ->
        Ecto.Changeset.change(%AuthorityRecord{}, record)
        |> Meadow.Repo.insert()
      end)

      # Search with limit of 2
      result =
        query_gql(
          variables: %{
            "authority" => "nul-authority",
            "query" => "Test Record",
            "limit" => 2
          },
          context: gql_context()
        )

      assert {:ok, %{data: query_data}} = result
      assert length(get_in(query_data, ["authoritiesSearch"])) == 2

      # Search with limit of 5
      result =
        query_gql(
          variables: %{
            "authority" => "nul-authority",
            "query" => "Test Record",
            "limit" => 5
          },
          context: gql_context()
        )

      assert {:ok, %{data: query_data}} = result
      assert length(get_in(query_data, ["authoritiesSearch"])) == 5

      # Search without limit (should default to 30)
      result =
        query_gql(
          variables: %{
            "authority" => "nul-authority",
            "query" => "Test Record"
          },
          context: gql_context()
        )

      assert {:ok, %{data: query_data}} = result
      # Should return all 5 records since it's less than the default limit of 30
      assert length(get_in(query_data, ["authoritiesSearch"])) == 5
    end
  end
end
