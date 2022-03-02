defmodule MeadowWeb.Schema.Query.GetMetadataUpdateJobByIdTest do
  use Meadow.DataCase
  use MeadowWeb.ConnCase, async: true
  use Meadow.CSVMetadataUpdateCase
  use Wormwood.GQLCase
  alias Meadow.Data.CSV.MetadataUpdateJobs

  load_gql(MeadowWeb.Schema, "test/gql/GetMetadataUpdateJobById.gql")

  setup %{source_url: source_url} do
    prewarm_controlled_term_cache()

    {:ok, job} =
      MetadataUpdateJobs.create_job(%{
        filename: Path.basename(source_url),
        source: source_url,
        user: "user1"
      })

    {:ok, %{job: job}}
  end

  describe "valid data" do
    @describetag source: "test/fixtures/csv/sheets/valid.csv"

    test "should be a valid query", %{job: job} do
      result =
        query_gql(
          variables: %{"id" => job.id},
          context: gql_context()
        )

      assert {:ok, query_data} = result

      assert get_in(query_data, [:data, "csvMetadataUpdateJob", "status"]) == "pending"
    end
  end

  describe "invalid data" do
    @describetag source: "test/fixtures/csv/sheets/invalid.csv"

    test "should report errors", %{job: job} do
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
                   "errors" => [%{"field" => "notes", "messages" => ["cannot have a blank id"]}],
                   "row" => 10
                 },
                 %{
                   "errors" => [
                     %{
                       "field" => "contributor#3",
                       "messages" => ["nop is an invalid coded term for scheme MARC_RELATOR"]
                     }
                   ],
                   "row" => 12
                 },
                 %{
                   "errors" => [
                     %{"field" => "id", "messages" => ["NOT_A_UUID is not a valid UUID"]}
                   ],
                   "row" => 13
                 },
                 %{
                   "errors" => [
                     %{
                       "field" => "date_created",
                       "messages" => ["[%{edtf: \"bad_date\"}, %{edtf: \"201?\"}] is invalid"]
                     }
                   ],
                   "row" => 14
                 },
                 %{
                   "errors" => [
                     %{
                       "field" => "id",
                       "messages" => ["0bde5432-0b7b-4f80-98fb-5f7ceff98dee not found"]
                     }
                   ],
                   "row" => 18
                 },
                 %{
                   "errors" => [%{"field" => "subject#3", "messages" => ["can't be blank"]}],
                   "row" => 21
                 },
                 %{
                   "errors" => [%{"field" => "reading_room", "messages" => ["tire is invalid"]}],
                   "row" => 24
                 },
                 %{
                   "errors" => [%{"field" => "published", "messages" => ["flase is invalid"]}],
                   "row" => 26
                 },
                 %{"errors" => [%{"field" => "id", "messages" => ["is required"]}], "row" => 28},
                 %{
                   "errors" => [
                     %{
                       "field" => "accession_number",
                       "messages" => ["MISMATCHED_ACCESSION does not match"]
                     }
                   ],
                   "row" => 37
                 }
               ]
      end
    end
  end
end
