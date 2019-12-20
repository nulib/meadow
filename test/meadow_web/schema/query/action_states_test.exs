defmodule MeadowWeb.Schema.Query.ActionStatesTest do
  use Meadow.IngestCase
  use MeadowWeb.ConnCase, async: true
  use Wormwood.GQLCase
  alias Meadow.Data.ActionStates
  alias Meadow.Pipeline.Actions.GenerateFileSetDigests
  import Assertions

  load_gql(MeadowWeb.Schema, "assets/js/gql/GetActionStates.gql")

  setup %{ingest_sheet: sheet} do
    sheet = create_works(sheet)
    {:ok, ingest_sheet: sheet, file_set: file_sets_for(sheet) |> List.first()}
  end

  test "initially empty", %{file_set: file_set} do
    {:ok, result} = query_gql(variables: %{"objectId" => file_set.id}, context: gql_context())
    assert(get_in(result, [:data, "actionStates"]) == [])
  end

  test "contains records", %{file_set: file_set} do
    ActionStates.set_state!(file_set, "Create FileSet", "ok")
    ActionStates.set_state!(file_set, Meadow.Pipeline.Actions.GenerateFileSetDigests, "ok")
    {:ok, result} = query_gql(variables: %{"objectId" => file_set.id}, context: gql_context())

    with trail <- get_in(result, [:data, "actionStates"]) do
      assert(length(trail) == 2)

      assert_lists_equal(trail |> Enum.map(fn %{"action" => v} -> v end), [
        "Create FileSet",
        GenerateFileSetDigests.actiondoc()
      ])

      assert_lists_equal(trail |> Enum.map(fn %{"outcome" => v} -> v end), ["OK", "OK"])
    end
  end
end
