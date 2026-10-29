defmodule MeadowWeb.Schema.Mutation.RetryFileSetPipelineTest do
  use Meadow.DataCase
  use MeadowWeb.ConnCase, async: false
  use Wormwood.GQLCase

  alias Meadow.Data.ActionStates
  alias Meadow.Pipeline.Actions.{ExtractMimeType, IngestFileSet, InitializeDispatch}

  load_gql(MeadowWeb.Schema, "test/gql/RetryFileSetPipeline.gql")

  setup do
    file_set =
      file_set_fixture(%{
        role: %{id: "A", scheme: "FILE_SET_ROLE"},
        core_metadata: %{
          location: "s3://test-ingest/retry/test.tif",
          original_filename: "test.tif",
          mime_type: "image/tiff"
        }
      })

    {:ok, file_set: file_set}
  end

  test "should be a valid mutation", %{file_set: file_set} do
    ActionStates.set_state!(file_set, IngestFileSet, "ok")
    ActionStates.set_state!(file_set, ExtractMimeType, "ok")
    ActionStates.set_state!(file_set, InitializeDispatch, "error", "it broke")

    result =
      query_gql(
        variables: %{"fileSetId" => file_set.id},
        context: gql_context()
      )

    assert {:ok, query_data} = result
    assert get_in(query_data, [:data, "retryFileSetPipeline", "id"]) == file_set.id

    assert ActionStates.get_latest_state(file_set.id, InitializeDispatch)
           |> Map.get(:outcome) == "waiting"
  end

  test "returns an error when there is nothing to retry", %{file_set: file_set} do
    ActionStates.set_state!(file_set, IngestFileSet, "ok")

    assert {:ok, query_data} =
             query_gql(
               variables: %{"fileSetId" => file_set.id},
               context: gql_context()
             )

    assert [%{message: message} | _] = query_data[:errors]
    assert message =~ "no failed actions to retry"
  end

  test "should reject users below editor", %{file_set: file_set} do
    assert {:ok, result} =
             query_gql(
               variables: %{"fileSetId" => file_set.id},
               context: gql_context(%{role: :user})
             )

    assert %{errors: [%{message: "Forbidden", status: 403}]} = result
  end
end
