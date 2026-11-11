defmodule Meadow.TranscriptionBench.ImageSizeTest do
  use ExUnit.Case, async: true

  alias Meadow.TranscriptionBench.ImageSize

  # The sizes are the worked examples of Anthropic's vision documentation.
  describe "resized/2" do
    test "the standard tier is bound by its tokens before its edge" do
      assert ImageSize.resized({1075, 1520}, :standard) == {924, 1307}
      assert ImageSize.resized({1920, 1080}, :standard) == {1456, 819}
      assert ImageSize.resized({3840, 2160}, :standard) == {1456, 819}
      assert ImageSize.resized({1000, 1000}, :standard) == {1000, 1000}
    end

    test "the high-resolution tier takes most pages as they are" do
      assert ImageSize.resized({1075, 1520}, :high) == {1075, 1520}
      assert ImageSize.resized({2000, 1500}, :high) == {2000, 1500}
      assert ImageSize.resized({3840, 2160}, :high) == {2576, 1449}
    end

    test "what the transcriber sends is resized when it is close to square" do
      assert ImageSize.resized({1097, 2048}, :high) == {1097, 2048}
      assert {side, side} = ImageSize.resized({2048, 2048}, :high)
      assert side < 2048
      assert ImageSize.tokens({side, side}) <= 4784
      assert ImageSize.tokens({side + 28, side + 28}) > 4784
    end
  end

  test "tokens/1 counts 28 pixel patches" do
    assert ImageSize.tokens({1075, 1520}) == 39 * 55
  end

  test "tier/1 is high from Claude 4.7 on" do
    for model <- ~w(us.anthropic.claude-sonnet-5-5 us.anthropic.claude-opus-4-7
                    us.anthropic.claude-fable-5-2 us.anthropic.claude-opus-5
                    global.anthropic.claude-opus-4-8-20260115-v1:0) do
      assert ImageSize.tier(model) == :high, model
    end

    for model <- ~w(us.anthropic.claude-sonnet-4-6 us.anthropic.claude-haiku-4-5-20251001-v1:0
                    us.anthropic.claude-opus-4-20250514-v1:0
                    us.anthropic.claude-3-7-sonnet-20250219-v1:0 something-else) do
      assert ImageSize.tier(model) == :standard, model
    end
  end

  test "tier/2 lets a variant say otherwise" do
    model = "us.anthropic.claude-sonnet-4-6"
    assert ImageSize.tier(model, %{"imageTier" => "high"}) == :high

    assert ImageSize.tier("us.anthropic.claude-opus-5-5", %{"imageTier" => "standard"}) ==
             :standard

    assert ImageSize.tier(model, %{"imageTier" => "auto"}) == :standard
    assert ImageSize.tier(model, %{}) == :standard
  end
end
