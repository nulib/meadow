defmodule MeadowWeb.Schema.Query.AuditTrailTest do
  use Meadow.IngestCase
  use MeadowWeb.ConnCase, async: true
  use Wormwood.GQLCase
  alias Meadow.Data.AuditEntries
  alias Meadow.Ingest.Actions.GenerateFileSetDigests

  load_gql(MeadowWeb.Schema, "assets/js/gql/GetAuditTrail.gql")

  setup %{ingest_sheet: sheet} do
    sheet = create_works(sheet)
    {:ok, ingest_sheet: sheet, file_set: file_sets_for(sheet) |> List.first()}
  end

  test "initially empty", %{file_set: file_set} do
    {:ok, result} = query_gql(variables: %{"objectId" => file_set.id}, context: gql_context())
    assert(get_in(result, [:data, "auditTrail"]) == [])
  end

  test "contains records", %{file_set: file_set} do
    AuditEntries.add_entry!(file_set, Meadow.Ingest.Actions.GenerateFileSetDigests, "ok")
    {:ok, result} = query_gql(variables: %{"objectId" => file_set.id}, context: gql_context())
    trail = get_in(result, [:data, "auditTrail"])
    assert(length(trail) == 1)
    assert(trail |> List.first() |> Map.get("action") == GenerateFileSetDigests.actiondoc())
    assert(trail |> List.first() |> Map.get("outcome") == "OK")
  end
end
