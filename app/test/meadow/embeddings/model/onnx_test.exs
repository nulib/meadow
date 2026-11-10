defmodule Meadow.Embeddings.Model.ONNXTest do
  @moduledoc """
  Runs the real model. Excluded by default because it needs the model files
  (about 1.8 GB with the vision encoder) on disk:

      mix meadow.embeddings.download
      mix test test/meadow/embeddings/model/onnx_test.exs --include manual
  """
  use ExUnit.Case, async: false

  alias Meadow.Embeddings.Model.ONNX
  alias Meadow.Embeddings.Prompt

  @moduletag manual: true
  @moduletag timeout: :infinity

  setup_all do
    {:ok, server: start_supervised!({ONNX, name: __MODULE__})}
  end

  defp dot(a, b), do: Enum.zip_with(a, b, &(&1 * &2)) |> Enum.sum()

  test "returns one normalized vector per prompt", %{server: server} do
    prompts = [Prompt.query("red planet"), Prompt.document(nil, "Mars is red.")]
    assert {:ok, [query, document]} = ONNX.embed(server, prompts)
    assert length(query) == 768
    assert length(document) == 768
    assert_in_delta dot(query, query), 1.0, 1.0e-3
    assert_in_delta dot(document, document), 1.0, 1.0e-3
  end

  test "ranks the relevant document first", %{server: server} do
    prompts = [
      Prompt.query("Which planet is known as the Red Planet?"),
      Prompt.document(nil, "Venus is often called Earth's twin because of its similar size."),
      Prompt.document(nil, "Mars, known for its reddish appearance, is the Red Planet."),
      Prompt.document(nil, "Jupiter, the largest planet, has a prominent red spot.")
    ]

    assert {:ok, [query | documents]} = ONNX.embed(server, prompts)
    scores = Enum.map(documents, &dot(query, &1))
    assert Enum.max(scores) == Enum.at(scores, 1)
  end

  test "batching and padding do not change a prompt's vector", %{server: server} do
    short = Prompt.document("Short", "A poster.")
    long = Prompt.document("Long", String.duplicate("A much longer description. ", 40))

    assert {:ok, [alone]} = ONNX.embed(server, [short])
    assert {:ok, [_, batched, _]} = ONNX.embed(server, [long, short, long])
    assert_in_delta dot(alone, batched), 1.0, 1.0e-3
  end

  describe "images" do
    @fixtures Path.expand("../../../../../embedding-fixtures", __DIR__)
    @images %{
      "coffee.tif" => "a cup of coffee",
      "douglass_letter.tif" => "a handwritten letter",
      "BFMF_B38_F10_025_002a.jpeg" => "a vinyl record"
    }

    setup %{server: server} do
      queries = Map.values(@images)
      {:ok, vectors} = ONNX.embed(server, Enum.map(queries, &Prompt.query/1))
      {:ok, queries: Enum.zip(queries, vectors)}
    end

    test "embeds images into the same space as text", %{server: server, queries: queries} do
      for {file, expected_query} <- @images do
        assert {:ok, image} = ONNX.embed_image(server, File.read!(Path.join(@fixtures, file)))
        assert length(image) == 768
        assert_in_delta dot(image, image), 1.0, 1.0e-3

        {best_query, _} = Enum.max_by(queries, fn {_, query} -> dot(query, image) end)
        assert best_query == expected_query, "#{file} matched #{inspect(best_query)}"
      end
    end

    test "matches the vectors transformers.js produces for the same files", %{server: server} do
      reference =
        "test/fixtures/embeddings/transformers_js_reference.json"
        |> File.read!()
        |> Jason.decode!()

      for {file, %{"embedding" => expected}} <- reference do
        assert {:ok, image} = ONNX.embed_image(server, File.read!(Path.join(@fixtures, file)))
        assert_in_delta dot(image, expected), 1.0, 1.0e-4, "#{file} differs from the reference"
      end
    end

    test "returns an error for something that is not an image", %{server: server} do
      assert {:error, _} = ONNX.embed_image(server, "not an image")
      assert {:ok, [_]} = ONNX.embed(server, [Prompt.query("still working")])
    end
  end

  test "returns nothing for no prompts", %{server: server} do
    assert ONNX.embed(server, []) == {:ok, []}
  end
end
