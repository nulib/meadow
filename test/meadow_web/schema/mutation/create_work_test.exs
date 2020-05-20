defmodule MeadowWeb.Schema.Mutation.CreateWorkTest do
  use MeadowWeb.ConnCase, async: true
  use Wormwood.GQLCase

  alias Authoritex.Mock
  alias Meadow.Data.Works
  alias Meadow.Repo

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
              "contributor" => %{"id" => "mock:result1", "role" => %{"id" => "aut"}}
            },
            "administrativeMetadata" => %{},
            "workType" => %{"id" => "IMAGE"},
            "visibility" => %{"id" => "OPEN"}
          },
          context: gql_context()
        )

      assert {:ok, query_data} = result

      title = get_in(query_data, [:data, "createWork", "descriptiveMetadata", "title"])
      assert title == "Something"

      work = Works.get_work_by_accession_number!("12345.abc")
    end
  end
end
