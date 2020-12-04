defmodule MeadowWeb.Schema.Query.GetMetadataUpdateJobByIdTest do
  use MeadowWeb.ConnCase, async: true
  use Wormwood.GQLCase
  alias Meadow.Data.CSV.MetadataUpdateJobs

  load_gql(MeadowWeb.Schema, "test/gql/GetMetadataUpdateJobById.gql")

  setup do
    prewarm_controlled_term_cache()

    jobs =
      [
        "test/fixtures/csv/work_fixture_update.csv",
        "test/fixtures/csv/work_fixture_update.csv",
        "test/fixtures/csv/work_fixture_update.csv"
      ]
      |> Enum.map(fn file ->
        with {:ok, job} <- "file://#{Path.expand(file)}" |> MetadataUpdateJobs.create_job() do
          {Path.basename(file), job}
        end
      end)
      |> Enum.into(%{})

    {:ok, %{jobs: jobs}}
  end

  test "should be a valid query", %{jobs: %{"work_fixture_update.csv" => job}} do
    result =
      query_gql(
        variables: %{"id" => job.id},
        context: gql_context()
      )

    assert {:ok, query_data} = result

    assert get_in(query_data, [:data, "csvMetadataUpdateJob", "status"]) == "pending"
  end
end
