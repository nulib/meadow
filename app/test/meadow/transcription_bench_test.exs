defmodule Meadow.TranscriptionBenchTest do
  use Meadow.DataCase, async: false

  alias Meadow.TranscriptionBench
  alias Meadow.TranscriptionBench.{Models, Result, Runner}

  @variant %{
    "id" => "lines",
    "name" => "Lines",
    "prompt" => "Transcribe this.",
    "outputMode" => "tool",
    "boxOrder" => "xyxy",
    "boxUnits" => "px"
  }

  defmodule StubClient do
    @moduledoc false
    def fetch_image("https://fail" <> _, _variant, _model),
      do: {:error, "The IIIF server answered 404"}

    def fetch_image(_url, _variant, "resizing"),
      do:
        {:ok,
         %{
           bytes: "jpeg",
           format: "jpeg",
           sent: {2000, 4000},
           processed: {1000, 2000},
           full: {3000, 6000}
         }}

    def fetch_image(_url, _variant, _model),
      do: {:ok, %{bytes: "jpeg", format: "jpeg", sent: {1000, 2000}, full: {3000, 6000}}}

    def request_body(variant, _image), do: {:ok, %{"prompt" => variant["prompt"]}}
    def redact(body, model), do: Map.put(body, "modelId", model)

    def converse("broken", _body), do: {:error, "ThrottlingException"}

    def converse("stuck", _body) do
      send(:bench_test, {:transcribing, self()})
      Process.sleep(:infinity)
    end

    def converse(_model, _body) do
      {:ok,
       %{
         tool_input: ~s({"lines": [{"text": "Dear Sir", "box": [100, 200, 500, 300]}]}),
         text: "",
         reasoning: "",
         stop_reason: "tool_use",
         usage: %{"inputTokens" => 1200, "outputTokens" => 30}
       }}
    end
  end

  defp image_file_set(attrs \\ %{}) do
    Map.merge(
      %{
        role: %{id: "A", scheme: "FILE_SET_ROLE"},
        core_metadata: %{
          location: "s3://bucket/image.tif",
          original_filename: "image.tif",
          label: "Page",
          mime_type: "image/tiff"
        },
        derivatives: %{"pyramid_tiff" => "s3://pyramids/image.tif"}
      },
      attrs
    )
    |> file_set_fixture_attrs()
  end

  defp transcribable_work(count, attrs \\ %{}) do
    file_sets = Enum.map(1..count, fn _ -> image_file_set() end)
    work_fixture(Map.put(attrs, :file_sets, file_sets))
  end

  defp run_fixture(file_sets, models \\ ["model-a"], variants \\ [@variant]) do
    {:ok, run} =
      TranscriptionBench.create_run(%{
        name: " A run ",
        author: "editor@example.edu",
        file_set_ids: Enum.map(file_sets, & &1.id),
        models: models,
        variants: variants
      })

    run
  end

  describe "list_transcribable_file_sets/1" do
    test "only access files that are images with a pyramid" do
      work = transcribable_work(2)

      others = [
        image_file_set(%{role: %{id: "P", scheme: "FILE_SET_ROLE"}}),
        image_file_set(%{derivatives: %{}}),
        image_file_set(%{
          core_metadata: %{
            location: "s3://bucket/a.pdf",
            original_filename: "a.pdf",
            mime_type: "application/pdf"
          }
        })
      ]

      work_fixture(%{file_sets: others})

      assert %{total: 2, file_sets: file_sets} = TranscriptionBench.list_transcribable_file_sets()

      assert Enum.sort(Enum.map(file_sets, & &1.id)) ==
               Enum.sort(Enum.map(work.file_sets, & &1.id))

      assert [%{label: "Page", work_title: "Test title", representative_image_url: url} | _] =
               file_sets

      assert url =~ hd(file_sets).id
    end

    test "pages" do
      transcribable_work(3)

      assert %{total: 3, file_sets: [_, _]} =
               TranscriptionBench.list_transcribable_file_sets(limit: 2)

      assert %{total: 3, file_sets: [_]} =
               TranscriptionBench.list_transcribable_file_sets(limit: 2, offset: 2)
    end

    test "filters by collection and by work" do
      collection = collection_fixture()

      in_collection =
        transcribable_work(1, %{
          collection_id: collection.id,
          accession_number: "BENCH_1",
          descriptive_metadata: %{title: "Letter from Frederick Douglass"}
        })

      transcribable_work(1)
      list = &TranscriptionBench.list_transcribable_file_sets/1
      [expected] = Enum.map(in_collection.file_sets, & &1.id)

      assert %{total: 1, file_sets: [%{id: ^expected, collection_id: collection_id}]} =
               list.(collection_id: collection.id)

      assert collection_id == collection.id
      assert %{total: 1, file_sets: [%{id: ^expected}]} = list.(work: in_collection.id)
      assert %{total: 1, file_sets: [%{id: ^expected}]} = list.(work: "BENCH_1")
      assert %{total: 1, file_sets: [%{id: ^expected}]} = list.(work: "  frederick ")
      assert %{total: 0} = list.(work: "100%")
      assert %{total: 0} = list.(collection_id: "not-a-uuid")
      assert %{total: 2} = list.(work: " ")
    end
  end

  describe "create_run/1" do
    test "queues a result for every file set, variant and model" do
      work = transcribable_work(2)
      run = run_fixture(work.file_sets, ["model-a", "model-b"])

      assert run.name == "A run"
      assert run.models == ["model-a", "model-b"]
      assert Enum.map(run.images, & &1["label"]) == ["Page", "Page"]

      run = TranscriptionBench.get_run(run.id)
      assert %{total: 4, active: 4, done: 0, failed: 0} = run
      [first_id, second_id] = Enum.map(work.file_sets, & &1.id)

      assert Enum.map(run.results, &{&1.file_set_id, &1.model, &1.status}) == [
               {first_id, "model-a", "queued"},
               {first_id, "model-b", "queued"},
               {second_id, "model-a", "queued"},
               {second_id, "model-b", "queued"}
             ]

      assert Enum.all?(run.results, &(&1.image_url =~ &1.file_set_id))
    end

    test "caps a run at #{TranscriptionBench.max_transcriptions()} transcriptions" do
      work = transcribable_work(3)
      ids = Enum.map(work.file_sets, & &1.id)
      variants = [@variant, Map.put(@variant, "id", "words")]
      attrs = %{file_set_ids: ids, models: ["a", "b"], variants: variants}

      assert {:error, message} = TranscriptionBench.create_run(attrs)
      assert message =~ "3 images x 2 models x 2 variants is 12 transcriptions"
      assert TranscriptionBench.list_runs() == []

      assert {:ok, _} = TranscriptionBench.create_run(%{attrs | models: ["a"]})
    end

    test "duplicates do not count twice" do
      [file_set] = transcribable_work(1).file_sets

      assert {:ok, run} =
               TranscriptionBench.create_run(%{
                 file_set_ids: List.duplicate(file_set.id, 6),
                 models: ["a", "a "],
                 variants: [@variant, @variant]
               })

      assert %{total: 1} = TranscriptionBench.get_run(run.id)
    end

    test "refuses an empty selection, a bad variant and an untranscribable file set" do
      [file_set] = transcribable_work(1).file_sets
      attrs = %{file_set_ids: [file_set.id], models: ["a"], variants: [@variant]}
      create = &TranscriptionBench.create_run/1

      assert {:error, "Pick at least" <> _} = create.(%{attrs | models: []})
      assert {:error, "Every variant" <> _} = create.(%{attrs | variants: [%{"id" => "x"}]})

      assert {:error, "Not transcribable" <> _} =
               create.(%{attrs | file_set_ids: [Ecto.UUID.generate()]})

      assert {:error, _} = create.(%{attrs | file_set_ids: ["nope"]})
    end
  end

  describe "Runner" do
    test "transcribes what is queued and keeps what came back" do
      [file_set] = transcribable_work(1).file_sets
      run = run_fixture([file_set], ["model-a", "broken"])

      assert :ok = Runner.execute(run.id, StubClient)

      assert %{total: 2, done: 1, failed: 1, active: 0, results: [done, failed]} =
               TranscriptionBench.get_run(run.id)

      assert %Result{status: "done", stop_reason: "tool_use", attempt: 1} = done
      assert {done.sent_width, done.sent_height} == {1000, 2000}
      assert {done.image_width, done.image_height} == {3000, 6000}
      assert done.usage == %{"inputTokens" => 1200, "outputTokens" => 30}
      assert done.request == %{"prompt" => "Transcribe this.", "modelId" => "model-a"}
      assert is_integer(done.duration_ms)

      assert %{"text" => "Dear Sir", "levels" => ["lines"], "regions" => [region]} = done.parsed
      assert region["box"] == [0.1, 0.1, 0.4, 0.05]

      assert %Result{status: "error", error: "ThrottlingException", parsed: nil} = failed
      assert failed.request["modelId"] == "broken"

      assert [%{total: 2, done: 1, failed: 1, active: 0}] = TranscriptionBench.list_runs()
    end

    test "pixel boxes are read against the size the model processed" do
      [file_set] = transcribable_work(1).file_sets
      run = run_fixture([file_set], ["resizing"])
      Runner.execute(run.id, StubClient)

      assert %{results: [result]} = TranscriptionBench.get_run(run.id)
      assert {result.sent_width, result.sent_height} == {2000, 4000}
      assert {result.processed_width, result.processed_height} == {1000, 2000}
      assert [%{"box" => [0.1, 0.1, 0.4, 0.05]}] = result.parsed["regions"]
    end

    test "an image that cannot be fetched is an error" do
      [file_set] = transcribable_work(1).file_sets
      run = run_fixture([file_set])

      Repo.update_all(Result, set: [image_url: "https://fail/iiif/3/x"])
      Runner.execute(run.id, StubClient)

      assert %{results: [%{status: "error", error: "The IIIF server answered 404"}]} =
               TranscriptionBench.get_run(run.id)
    end

    test "a result is transcribed once, and again as a new attempt when retried" do
      [file_set] = transcribable_work(1).file_sets
      run = run_fixture([file_set])
      [queued] = TranscriptionBench.queued_results(run.id)

      assert TranscriptionBench.claim_result(queued)
      refute TranscriptionBench.claim_result(queued)
      assert {:error, _} = TranscriptionBench.retry_result(queued.id)

      TranscriptionBench.finish_result(queued, %{status: "done", text: "first"})
      assert {:ok, run_id} = TranscriptionBench.retry_result(queued.id)
      assert run_id == run.id

      assert %{results: [%{status: "queued", attempt: 2, text: nil, image_url: url}]} =
               TranscriptionBench.get_run(run.id)

      assert url =~ file_set.id

      # The first attempt, finishing late, does not overwrite the second.
      TranscriptionBench.finish_result(queued, %{status: "done", text: "late"})
      Runner.execute(run.id, StubClient)

      assert %{results: [%{status: "done", attempt: 2, text: ""}]} =
               TranscriptionBench.get_run(run.id)
    end
  end

  describe "cancelling" do
    test "a queued result is never sent, and can be run again" do
      [file_set] = transcribable_work(1).file_sets
      run = run_fixture([file_set], ["model-a", "model-b"])
      [first, _second] = TranscriptionBench.queued_results(run.id)

      assert {:ok, run_id} = TranscriptionBench.cancel_result(first.id)
      assert run_id == run.id
      assert {:error, _} = TranscriptionBench.cancel_result(first.id)
      assert {:error, _} = TranscriptionBench.cancel_result(Ecto.UUID.generate())

      Runner.execute(run.id, StubClient)

      assert %{done: 1, cancelled: 1, failed: 0, active: 0, results: [cancelled, done]} =
               TranscriptionBench.get_run(run.id)

      assert %{status: "cancelled", request: nil} = cancelled
      assert %{status: "done"} = done

      assert {:ok, _} = TranscriptionBench.retry_result(first.id)
      Runner.execute(run.id, StubClient)
      assert %{done: 2, cancelled: 0} = TranscriptionBench.get_run(run.id)
    end

    test "a run stops what it is transcribing and drops what is queued" do
      Process.register(self(), :bench_test)
      [file_set] = transcribable_work(1).file_sets
      run = run_fixture([file_set], ["stuck", "model-a", "model-b", "model-c", "model-d"])

      runner = Task.async(fn -> Runner.execute(run.id, StubClient) end)
      assert_receive {:transcribing, stuck}, 2_000
      monitor = Process.monitor(stuck)

      assert {:ok, _} = TranscriptionBench.cancel_run(run.id)
      assert_receive {:DOWN, ^monitor, :process, ^stuck, :killed}, 2_000
      assert Task.await(runner) == :ok

      assert %{active: 0, failed: 0, results: results} = TranscriptionBench.get_run(run.id)
      assert %{status: "cancelled"} = Enum.find(results, &(&1.model == "stuck"))
      assert Enum.all?(results, &(&1.status in ["cancelled", "done"]))

      assert {:ok, _} = TranscriptionBench.delete_run(run.id)
      assert {:error, _} = TranscriptionBench.cancel_run("nope")
    end
  end

  describe "delete_run/1" do
    test "deletes a finished run and keeps one that is transcribing" do
      [file_set] = transcribable_work(1).file_sets
      run = run_fixture([file_set])

      assert {:error, "This run is still transcribing"} = TranscriptionBench.delete_run(run.id)

      Runner.execute(run.id, StubClient)
      assert {:ok, _} = TranscriptionBench.delete_run(run.id)
      assert TranscriptionBench.get_run(run.id) == nil
      assert Repo.aggregate(Result, :count) == 0
      assert {:error, _} = TranscriptionBench.delete_run(run.id)
    end

    test "a run abandoned by its node is marked interrupted and can be deleted" do
      [file_set] = transcribable_work(1).file_sets
      run = run_fixture([file_set])
      long_ago = DateTime.add(DateTime.utc_now(), -3600, :second)
      Repo.update_all(Result, set: [status: "running", updated_at: long_ago])

      assert %{failed: 1, active: 0, results: [%{error: "Interrupted" <> _}]} =
               TranscriptionBench.get_run(run.id)

      assert {:ok, _} = TranscriptionBench.delete_run(run.id)
    end
  end

  test "Models.label/1 names a model as people do" do
    assert Models.label("us.anthropic.claude-sonnet-4-6") == "Sonnet 4.6"
    assert Models.label("us.anthropic.claude-opus-5-5") == "Opus 5.5"
    assert Models.label("us.anthropic.claude-haiku-4-5-20251001-v1:0") == "Haiku 4.5"
    assert Models.label("us.anthropic.claude-3-7-sonnet-20250219-v1:0") == "3 7 sonnet"
  end
end
