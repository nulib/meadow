defmodule MeadowWeb.Schema.Query.GetMetadataUpdateJobsTest do
  use Meadow.DataCase
  use MeadowWeb.ConnCase, async: true
  use Wormwood.GQLCase
  alias Meadow.Data.CSV.MetadataUpdateJobs

  load_gql(MeadowWeb.Schema, "test/gql/GetMetadataUpdateJobs.gql")

  test "should be a valid query" do
    prewarm_controlled_term_cache()

    [
      "test/fixtures/csv/sheets/valid.csv",
      "test/fixtures/csv/sheets/bad_headers.csv",
      "test/fixtures/csv/sheets/invalid.csv"
    ]
    |> Enum.each(fn file ->
      MetadataUpdateJobs.create_job(%{
        filename: Path.basename(file),
        source: "file://#{Path.expand(file)}"
      })
    end)

    result =
      query_gql(
        variables: %{},
        context: gql_context()
      )

    assert {:ok, query_data} = result

    jobs = get_in(query_data, [:data, "csvMetadataUpdateJobs"])
    assert length(jobs) == 3
  end
end
