defmodule MeadowWeb.Schema.Mutation.CreateSheet do
  use MeadowWeb.ConnCase, async: true
  use Wormwood.GQLCase

  load_gql(MeadowWeb.Schema, "test/gql/CreateIngestSheet.gql")

  test "should be a valid mutation" do
    project = project_fixture()

    result =
      query_gql(
        variables: %{
          "title" => "Test Ingest Sheet",
          "filename" => "Test.csv",
          "projectId" => project.id
        },
        context: gql_context()
      )

    assert {:ok, query_data} = result

    title = get_in(query_data, [:data, "createIngestSheet", "title"])
    assert title == "Test Ingest Sheet"
  end

  describe "authorization" do
    test "viewers are not authorized to create ingest sheets" do
      project = project_fixture()

      {:ok, result} =
        query_gql(
          variables: %{
            "title" => "Test Ingest Sheet",
            "filename" => "Test.csv",
            "projectId" => project.id
          },
          context: %{current_user: %{role: "User"}}
        )

      assert %{errors: [%{message: "Forbidden", status: 403}]} = result
    end

    test "editors and above are authorized to create ingest sheets" do
      project = project_fixture()

      {:ok, result} =
        query_gql(
          variables: %{
            "title" => "Test Ingest Sheet",
            "filename" => "Test.csv",
            "projectId" => project.id
          },
          context: %{current_user: %{role: "Editor"}}
        )

      assert result.data["createIngestSheet"]
    end
  end
end
