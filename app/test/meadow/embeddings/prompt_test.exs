defmodule Meadow.Embeddings.PromptTest do
  use ExUnit.Case, async: true

  alias Meadow.Embeddings.Prompt

  doctest Meadow.Embeddings.Prompt

  describe "document/2" do
    test "uses the title when there is one" do
      assert Prompt.document("A Title", "body") == "title: A Title | text: body"
    end

    test "collapses whitespace in the title" do
      assert Prompt.document("  A\n Title ", "body") == "title: A Title | text: body"
    end

    test "falls back to none for a missing or blank title" do
      for title <- [nil, "", "   ", ["not", "a", "string"]] do
        assert Prompt.document(title, "body") == "title: none | text: body"
      end
    end
  end

  test "query/1" do
    assert Prompt.query("maps of Chicago") == "task: search result | query: maps of Chicago"
  end
end
