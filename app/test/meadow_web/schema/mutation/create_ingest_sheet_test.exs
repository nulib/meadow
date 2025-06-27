defmodule MeadowWeb.Schema.Mutation.CreateSheet do
  use Meadow.DataCase
  use Meadow.S3Case
  use MeadowWeb.ConnCase, async: true
  use Wormwood.GQLCase

  load_gql(MeadowWeb.Schema, "test/gql/CreateIngestSheet.gql")

  @sheet_key "/create_sheet_test/ingest_sheet.csv"
  @sheet_fixture "test/fixtures/ingest_sheet.csv"
  @image_fixture "test/fixtures/coffee.tif"

  setup do
    project = project_fixture(%{id: "47b69292-604f-4ce3-b25f-65869d9ff562d"})

    upload_object(
      @upload_bucket,
      @sheet_key,
      File.read!(@sheet_fixture)
    )

    upload_object(
      @ingest_bucket,
      "#{project.folder}/coffee.tif",
      File.read!(@image_fixture)
    )

    on_exit(fn ->
      delete_object(@upload_bucket, @sheet_key)
      delete_object(@ingest_bucket, "#{project.folder}/coffee.tif")
    end)

    {:ok, %{project: project}}
  end

  test "should be a valid mutation", %{project: project} do
    result =
      query_gql(
        variables: %{
          "title" => "Test Ingest Sheet",
          "filename" => @sheet_key,
          "projectId" => project.id
        },
        context: gql_context()
      )

    assert {:ok, query_data} = result

    title = get_in(query_data, [:data, "createIngestSheet", "title"])
    assert title == "Test Ingest Sheet"
  end

  describe "authorization" do
    test "viewers are not authorized to create ingest sheets", %{project: project} do
      {:ok, result} =
        query_gql(
          variables: %{
            "title" => "Test Ingest Sheet",
            "filename" => @sheet_key,
            "projectId" => project.id
          },
          context: %{current_user: %{role: :user}}
        )

      assert %{errors: [%{message: "Forbidden", status: 403}]} = result
    end

    test "editors and above are authorized to create ingest sheets", %{project: project} do
      {:ok, result} =
        query_gql(
          variables: %{
            "title" => "Test Ingest Sheet",
            "filename" => @sheet_key,
            "projectId" => project.id
          },
          context: %{current_user: %{role: :editor}}
        )

      assert result.data["createIngestSheet"]
    end
  end
end
