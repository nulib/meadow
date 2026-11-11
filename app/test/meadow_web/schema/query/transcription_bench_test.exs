defmodule MeadowWeb.Schema.Query.TranscriptionBenchTest do
  use Meadow.DataCase, async: false

  alias Meadow.TranscriptionBench

  @variant %{"id" => "lines", "name" => "Lines", "prompt" => "Transcribe this."}

  setup do
    file_sets =
      Enum.map(1..3, fn index ->
        file_set_fixture_attrs(%{
          role: %{id: "A", scheme: "FILE_SET_ROLE"},
          core_metadata: %{
            location: "s3://bucket/page-#{index}.tif",
            original_filename: "page-#{index}.tif",
            mime_type: "image/tiff"
          },
          derivatives: %{"pyramid_tiff" => "s3://pyramids/page-#{index}.tif"}
        })
      end)

    {:ok, work: work_fixture(%{file_sets: file_sets})}
  end

  defp run(document, variables \\ %{}) do
    Absinthe.run(document, MeadowWeb.Schema, variables: variables, context: gql_context())
  end

  test "transcribableFileSets pages through the file sets of a work", %{work: work} do
    query = """
    query ($work: String, $limit: Int, $offset: Int) {
      transcribableFileSets(work: $work, limit: $limit, offset: $offset) {
        total
        fileSets { id label representativeImageUrl workId workTitle }
      }
    }
    """

    assert {:ok, %{data: %{"transcribableFileSets" => page}}} =
             run(query, %{"work" => work.id, "limit" => 2, "offset" => 2})

    assert %{"total" => 3, "fileSets" => [file_set]} = page
    assert %{"label" => "page-" <> _, "workTitle" => "Test title"} = file_set
    assert file_set["workId"] == work.id
    assert file_set["representativeImageUrl"] =~ file_set["id"]
  end

  test "requires an editor" do
    assert {:ok, %{errors: [%{message: "Forbidden"}]}} =
             Absinthe.run("{ transcriptionBenchRuns { id } }", MeadowWeb.Schema,
               context: gql_context(%{role: :user})
             )
  end

  describe "runs" do
    @start """
    mutation ($fileSetIds: [ID!]!, $models: [String!]!, $variants: Json!) {
      startTranscriptionBenchRun(fileSetIds: $fileSetIds, models: $models, variants: $variants) {
        id
      }
    }
    """

    test "startTranscriptionBenchRun refuses more than the cap", %{work: work} do
      variables = %{
        "fileSetIds" => Enum.map(work.file_sets, & &1.id),
        "models" => ["a", "b"],
        "variants" => Jason.encode!([@variant, Map.put(@variant, "id", "words")])
      }

      assert {:ok, %{errors: [%{message: message}]}} = run(@start, variables)
      assert message =~ "capped at 10"

      assert {:ok, %{errors: [%{message: "variants must be a JSON array"}]}} =
               run(@start, %{variables | "variants" => ~s({"id": "lines"})})

      assert TranscriptionBench.list_runs() == []
    end

    test "transcriptionBenchRuns, transcriptionBenchRun and delete", %{work: work} do
      {:ok, %{id: id}} =
        TranscriptionBench.create_run(%{
          name: "First",
          author: "editor@example.edu",
          file_set_ids: Enum.map(work.file_sets, & &1.id),
          models: ["us.anthropic.claude-sonnet-4-6"],
          variants: [@variant]
        })

      assert {:ok, %{data: %{"transcriptionBenchRuns" => [summary]}}} =
               run("""
               { transcriptionBenchRuns {
                   id name author models images variants total done failed active
               } }
               """)

      assert %{"id" => ^id, "name" => "First", "total" => 3, "active" => 3} = summary
      assert [%{"fileSetId" => _, "label" => "page-" <> _} | _] = summary["images"]
      assert summary["variants"] == [@variant]

      query = """
      query ($id: ID!) { transcriptionBenchRun(id: $id) {
        total
        results { id attempt fileSetId label imageUrl model variantId status parsed usage }
      } }
      """

      assert {:ok, %{data: %{"transcriptionBenchRun" => %{"total" => 3, "results" => results}}}} =
               run(query, %{"id" => id})

      assert [%{"status" => "queued", "attempt" => 1, "variantId" => "lines"} | _] = results

      delete = "mutation ($id: ID!) { deleteTranscriptionBenchRun(id: $id) { id } }"

      assert {:ok, %{errors: [%{message: "This run is still transcribing"}]}} =
               run(delete, %{"id" => id})

      Meadow.Repo.update_all(TranscriptionBench.Result, set: [status: "error"])

      assert {:ok, %{data: %{"deleteTranscriptionBenchRun" => %{"id" => ^id}}}} =
               run(delete, %{"id" => id})

      assert {:ok, %{errors: [%{message: "Transcription run not found"}]}} =
               run(query, %{"id" => id})
    end
  end
end
