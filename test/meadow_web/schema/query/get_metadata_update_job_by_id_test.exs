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
        "test/fixtures/csv/work_fixture_update_bad_headers.csv",
        "test/fixtures/csv/work_fixture_update_invalid.csv"
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

  test "should report errors", %{jobs: %{"work_fixture_update_invalid.csv" => job}} do
    MetadataUpdateJobs.apply_job(job)

    result =
      query_gql(
        variables: %{"id" => job.id},
        context: gql_context()
      )

    assert {:ok, query_data} = result

    assert get_in(query_data, [:data, "csvMetadataUpdateJob", "status"]) == "invalid"

    with errors <- get_in(query_data, [:data, "csvMetadataUpdateJob", "errors"]) do
      assert errors == [
               %{
                 "row" => 12,
                 "errors" => [
                   %{
                     "field" => "contributor#3",
                     "messages" => ["nop is an invalid coded term for scheme MARC_RELATOR"]
                   }
                 ]
               },
               %{
                 "row" => 14,
                 "errors" => [
                   %{
                     "field" => "date_created",
                     "messages" => ["[%{edtf: \"bad_date\"}, %{edtf: \"201?\"}] is invalid"]
                   }
                 ]
               }
             ]
    end
  end
end
