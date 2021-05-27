defmodule MeadowWeb.Schema.Query.ActionStatesTest do
  use Meadow.IngestCase
  use MeadowWeb.ConnCase, async: true
  use Wormwood.GQLCase
  alias Meadow.Data.ActionStates
  alias Meadow.Pipeline.Actions.{GenerateFileSetDigests, IngestFileSet}
  import Assertions

  load_gql(MeadowWeb.Schema, "test/gql/GetActionStates.gql")

  setup %{ingest_sheet: sheet} do
    sheet = create_works(sheet)
    {:ok, ingest_sheet: sheet, file_set: file_sets_for(sheet) |> List.first()}
  end

  test "initializes properly", %{file_set: file_set} do
    {:ok, result} = query_gql(variables: %{"objectId" => file_set.id}, context: gql_context())

    with trail <- get_in(result, [:data, "actionStates"]) do
      case file_set.role.id do
        "A" ->
          assert(length(trail) == 8)

        "P" ->
          assert(length(trail) == 6)
      end

      assert_all_have_value(trail, "outcome", "WAITING")
    end
  end

  test "contains records", %{file_set: file_set} do
    ActionStates.set_state!(file_set, IngestFileSet, "ok")
    ActionStates.set_state!(file_set, GenerateFileSetDigests, "ok")
    {:ok, result} = query_gql(variables: %{"objectId" => file_set.id}, context: gql_context())

    with trail <- get_in(result, [:data, "actionStates"]) do
      case file_set.role.id do
        "A" ->
          assert(length(trail) == 8)

        "P" ->
          assert(length(trail) == 6)
      end

      assert(
        Enum.all?(trail, fn %{"action" => action, "outcome" => outcome} ->
          case action do
            "Start Ingesting a FileSet" -> outcome == "OK"
            "Generate Digests for FileSet" -> outcome == "OK"
            _ -> outcome == "WAITING"
          end
        end)
      )
    end
  end
end
