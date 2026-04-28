defmodule MeadowWeb.Schema.Mutation.TranscribeFileSetTest do
  use Meadow.DataCase
  use MeadowWeb.ConnCase, async: false
  use Wormwood.GQLCase

  load_gql(MeadowWeb.Schema, "test/gql/TranscribeFileSet.gql")

  test "returns human-readable changeset details when transcription cannot be created" do
    original_ai_config = Application.get_env(:meadow, :ai, [])

    on_exit(fn ->
      Application.put_env(:meadow, :ai, original_ai_config)
    end)

    Application.put_env(:meadow, :ai, Keyword.put(original_ai_config, :transcriber_model, []))

    work =
      work_with_file_sets_fixture(1, %{work_type: %{id: "IMAGE", scheme: "work_type"}}, %{
        role: %{id: "A", scheme: "FILE_SET_ROLE"}
      })

    file_set = List.first(work.file_sets)

    result =
      query_gql(
        variables: %{"fileSetId" => file_set.id},
        context: gql_context()
      )

    assert {:ok, %{data: %{"transcribeFileSet" => nil}, errors: [error]}} = result
    assert error.message == "Could not transcribe file_set"
    assert error.details == %{"model" => "is invalid"}
    refute inspect(error.details) =~ "Ecto.Changeset"
  end
end
