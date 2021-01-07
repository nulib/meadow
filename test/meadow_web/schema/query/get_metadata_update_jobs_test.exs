defmodule MeadowWeb.Schema.Query.GetMetadataUpdateJobsTest do
  use MeadowWeb.ConnCase, async: true
  use Wormwood.GQLCase
  alias Meadow.Data.CSV.MetadataUpdateJobs

  load_gql(MeadowWeb.Schema, "test/gql/GetMetadataUpdateJobs.gql")

  test "should be a valid query" do
    prewarm_controlled_term_cache()

    [
      "test/fixtures/csv/work_fixture_update.csv",
      "test/fixtures/csv/work_fixture_update_bad_headers.csv",
      "test/fixtures/csv/work_fixture_update_invalid.csv"
    ]
    |> Enum.each(fn file ->
      "file://#{Path.expand(file)}"
      |> MetadataUpdateJobs.create_job()
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
