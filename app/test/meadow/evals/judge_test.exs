defmodule Meadow.Evals.JudgeTest do
  use ExUnit.Case, async: true

  alias Meadow.Evals.Judge

  describe "build_request_body/2 tool schema" do
    setup do
      %{body: Judge.build_request_body("score this", {:error, :no_image})}
    end

    test "forces the model to call the submit_evaluation tool", %{body: body} do
      assert %{
               "toolConfig" => %{
                 "toolChoice" => %{"tool" => %{"name" => "submit_evaluation"}},
                 "tools" => [%{"toolSpec" => %{"name" => "submit_evaluation"} = spec}]
               }
             } = body

      assert spec["inputSchema"]["json"]["required"] == [
               "description_score",
               "subjects_score",
               "rationale"
             ]
    end

    test "declares both scores as nullable, bounded numbers", %{body: body} do
      props =
        get_in(body, [
          "toolConfig",
          "tools",
          Access.at(0),
          "toolSpec",
          "inputSchema",
          "json",
          "properties"
        ])

      for field <- ["description_score", "subjects_score"] do
        assert props[field]["type"] == ["number", "null"]
        assert props[field]["minimum"] == 0.0
        assert props[field]["maximum"] == 1.0
      end

      assert props["rationale"]["type"] == "string"
    end

    test "sends prompt as text only when no image is available", %{body: body} do
      assert %{"messages" => [%{"role" => "user", "content" => [%{"text" => "score this"}]}]} = body
    end

    test "prepends an image block when an image is provided" do
      body = Judge.build_request_body("score this", {:ok, "ZmFrZQ=="})

      assert %{
               "messages" => [
                 %{
                   "content" => [
                     %{"image" => %{"format" => "jpeg", "source" => %{"bytes" => "ZmFrZQ=="}}},
                     %{"text" => "score this"}
                   ]
                 }
               ]
             } = body
    end
  end

  describe "extract_scores/1" do
    test "maps tool input onto trial judge fields" do
      input = %{
        "description_score" => 0.8,
        "subjects_score" => 0.6,
        "rationale" => "Covers the key facts."
      }

      assert Judge.extract_scores(input) == %{
               description_judge_score: 0.8,
               subjects_judge_score: 0.6,
               judge_rationale: "Covers the key facts."
             }
    end

    test "passes through null scores as nil (no usable ground truth)" do
      input = %{
        "description_score" => nil,
        "subjects_score" => 0.5,
        "rationale" => "No cataloger description."
      }

      assert %{description_judge_score: nil, subjects_judge_score: 0.5} =
               Judge.extract_scores(input)
    end

    test "clamps out-of-range scores into 0.0–1.0" do
      input = %{"description_score" => 1.4, "subjects_score" => -0.2, "rationale" => "x"}

      assert %{description_judge_score: 1.0, subjects_judge_score: +0.0} =
               Judge.extract_scores(input)
    end

    test "coerces numeric strings and rejects unparseable values" do
      input = %{"description_score" => "0.75", "subjects_score" => "n/a", "rationale" => "x"}

      assert %{description_judge_score: 0.75, subjects_judge_score: nil} =
               Judge.extract_scores(input)
    end

    test "keeps full-length rationales but caps runaway ones" do
      typical = String.duplicate("a", 600)

      assert %{judge_rationale: ^typical} = Judge.extract_scores(%{"rationale" => typical})

      runaway = String.duplicate("a", 3000)
      assert %{judge_rationale: capped} = Judge.extract_scores(%{"rationale" => runaway})
      assert String.length(capped) == 2000

      assert %{judge_rationale: nil} = Judge.extract_scores(%{"rationale" => ""})
      assert %{judge_rationale: nil} = Judge.extract_scores(%{})
    end
  end
end
