defmodule Meadow.TranscriptionBench.ParserTest do
  use ExUnit.Case, async: true

  alias Meadow.TranscriptionBench.Parser

  @px %{order: "xyxy", units: "px"}
  @size {2000, 1000}

  defp parse(output), do: Parser.parse(output, @px, @size)

  test "lines with pixel boxes become fractions of the image" do
    parsed =
      parse(
        Jason.encode!(%{
          lines: [
            %{text: "Dear  Sir,\n", box: [200, 100, 600, 150]},
            %{text: "   ", box: [0, 0, 10, 10]},
            %{text: "no box"}
          ],
          detected_languages: ["en"]
        })
      )

    assert parsed["levels"] == ["lines"]
    assert parsed["text"] == "Dear Sir,\nno box"
    assert [first, second] = parsed["regions"]
    assert first["box"] == [0.1, 0.1, 0.2, 0.05]
    assert first["rawBox"] == [200, 100, 600, 150]
    assert second["box"] == nil
    assert parsed["languages"] == ["en"]
    assert parsed["structured"]
  end

  test "nested words are a second level under their line" do
    parsed =
      parse(~s({"lines": [{"text": "Space Age", "box": [0, 0, 100, 20], "words": [
        {"text": "Space", "box": [0, 0, 45, 20]}, {"text": "Age", "box": [55, 0, 100, 20]}]}]}))

    assert parsed["levels"] == ["lines", "words"]
    assert parsed["text"] == "Space Age"

    assert Enum.map(parsed["regions"], &{&1["level"], &1["text"], &1["parent"]}) == [
             {"lines", "Space Age", nil},
             {"words", "Space", 0},
             {"words", "Age", 0}
           ]
  end

  test "levels keep the order the model gave them" do
    parsed =
      parse(~s({"words": [{"text": "b", "box": [0, 0, 10, 10]}], "headings": [{"text": "a"}]}))

    assert parsed["levels"] == ["words", "headings"]
    assert parsed["text"] == "b"
  end

  test "the text-only shape, a blank page, and an answer that is not JSON" do
    assert parse(~s({"transcribed_text": " hello "}))["text"] == "hello"
    assert parse(~s({"lines": [], "detected_languages": []}))["text"] == "[blank page]"

    plain = parse("Just words.")
    assert plain["text"] == "Just words."
    refute plain["structured"]
    assert parse(nil)["text"] == ""
  end

  test "JSON in a code fence, and a lines array sent as a string" do
    fenced = parse(~s(Here:\n```json\n{"words":[{"text":"a","box":[0,0,10,10]}]}\n```))
    assert fenced["levels"] == ["words"]

    stringified =
      parse(Jason.encode!(%{lines: Jason.encode!([%{text: "a", box: [0, 0, 10, 10]}])}))

    assert length(stringified["regions"]) == 1
    assert stringified["warnings"] == ["An array arrived as a JSON string."]
  end

  test "a stringified array that is not valid JSON is recovered by pattern" do
    lines =
      ~s([\n {"text": "Prokofiev's "Cinderella"\\nat 11", "box": [0, 0, 100, 20]},\n ) <>
        ~s({"text": "Music", "box": [0, 30, 100, 50]})

    parsed = parse(Jason.encode!(%{lines: lines, detected_languages: ["en"]}))

    assert Enum.map(parsed["regions"], & &1["text"]) == [
             ~s(Prokofiev's "Cinderella" at 11),
             "Music"
           ]

    assert Enum.at(parsed["regions"], 1)["box"] == [0.0, 0.03, 0.05, 0.02]
    assert length(parsed["warnings"]) == 1
  end

  test "box orders, units, quadrilaterals and degenerate boxes" do
    box = &Parser.normalize_box/3

    assert box.([100, 200, 300, 400], %{order: "xywh", units: "1000"}, nil) ==
             [0.1, 0.2, 0.3, 0.4]

    assert box.([200, 100, 600, 400], %{order: "yxyx", units: "1000"}, nil) ==
             [0.1, 0.2, 0.3, 0.4]

    assert box.([0.1, 0.2, 0.4, 0.6], %{order: "xyxy", units: "frac"}, nil) ==
             [0.1, 0.2, 0.3, 0.4]

    assert box.([200, 100, 600, 110, 600, 150, 200, 140], @px, @size) == [0.1, 0.1, 0.2, 0.05]
    assert box.([-50, 0, 4000, 500], @px, @size) == [0.0, 0.0, 1.0, 0.5]
    assert box.([10, 10, 10, 50], @px, @size) == nil
    assert box.([10, 10, 50], @px, @size) == nil
    assert box.([10, 10, 50, 60], @px, nil) == nil
    assert box.("somewhere", @px, @size) == nil

    object = Parser.read_json(~s({"x": 200, "y": 100, "width": 400, "height": 50}))
    assert box.(object, @px, @size) == [0.1, 0.1, 0.2, 0.05]
  end
end
