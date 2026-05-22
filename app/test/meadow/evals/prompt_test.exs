defmodule Meadow.Evals.PromptTest do
  use ExUnit.Case, async: true

  alias Meadow.Evals

  describe "eval_tool_prompt/1" do
    test "normalizes eval tool names to Claude MCP namespaced tools" do
      prompt = """
      Call get_image, authority_search, and submit_eval_metadata.
      Do not call apply_work_metadata.
      """

      normalized = Evals.eval_tool_prompt(prompt)

      assert normalized =~ "mcp__meadow__get_iiif_image"
      assert normalized =~ "mcp__meadow__authority_search"
      assert normalized =~ "mcp__meadow__submit_eval_metadata"
      refute normalized =~ " get_image"
      refute normalized =~ " apply_work_metadata"
    end

    test "does not double-prefix already namespaced tools" do
      prompt = "Call mcp__meadow__get_iiif_image and mcp__meadow__submit_eval_metadata."

      assert Evals.eval_tool_prompt(prompt) == prompt
    end
  end
end
