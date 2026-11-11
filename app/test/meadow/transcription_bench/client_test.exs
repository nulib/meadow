defmodule Meadow.TranscriptionBench.ClientTest do
  use ExUnit.Case, async: true

  alias Meadow.TranscriptionBench.Client

  @image %{bytes: "jpeg", format: "jpeg", sent: {1536, 2048}, full: {3000, 4000}}
  @variant %{
    "id" => "lines",
    "name" => "Lines",
    "system" => "",
    "prompt" => "Use {{tool_name}} on this {{width}} x {{height}} image.",
    "outputMode" => "tool",
    "toolName" => "transcribe",
    "toolDescription" => "For a {{width}} px wide image",
    "toolSchema" => ~s({"type": "object", "properties": {"lines": {"type": "array"}}}),
    "toolChoice" => "auto",
    "maxTokens" => 32_000,
    "temperature" => nil,
    "additionalFields" => ""
  }

  describe "request_body/2" do
    test "is the Converse request Meadow's transcriber sends" do
      assert {:ok, body} = Client.request_body(@variant, @image)

      assert [%{"role" => "user", "content" => [image, text]}] = body["messages"]
      assert image == %{"image" => %{"format" => "jpeg", "source" => %{"bytes" => "anBlZw=="}}}
      assert text == %{"text" => "Use transcribe on this 1536 x 2048 image."}
      assert body["inferenceConfig"] == %{"maxTokens" => 32_000}
      refute Map.has_key?(body, "system")
      refute Map.has_key?(body, "additionalModelRequestFields")

      assert %{"tools" => [%{"toolSpec" => spec}], "toolChoice" => %{"auto" => %{}}} =
               body["toolConfig"]

      assert spec["name"] == "transcribe"
      assert spec["description"] == "For a 1536 px wide image"
      assert spec["inputSchema"]["json"]["properties"]["lines"] == %{"type" => "array"}
    end

    test "system prompt, temperature, forced tool and additional fields" do
      variant =
        Map.merge(@variant, %{
          "system" => "You transcribe.",
          "temperature" => 0,
          "toolChoice" => "tool",
          "maxTokens" => 1_000_000,
          "additionalFields" => ~s({"thinking": {"type": "adaptive"}})
        })

      assert {:ok, body} = Client.request_body(variant, @image)
      assert body["system"] == [%{"text" => "You transcribe."}]
      assert body["inferenceConfig"] == %{"maxTokens" => 64_000, "temperature" => 0}
      assert body["toolConfig"]["toolChoice"] == %{"tool" => %{"name" => "transcribe"}}
      assert body["additionalModelRequestFields"] == %{"thinking" => %{"type" => "adaptive"}}
    end

    test "a plain text answer has no tools" do
      assert {:ok, body} = Client.request_body(Map.put(@variant, "outputMode", "text"), @image)
      refute Map.has_key?(body, "toolConfig")
    end

    test "says what is wrong with a variant's JSON" do
      assert {:error, "The tool schema is not valid JSON" <> _} =
               Client.request_body(Map.put(@variant, "toolSchema", "{nope"), @image)

      assert {:error, "Additional model request fields are not valid JSON" <> _} =
               Client.request_body(Map.put(@variant, "additionalFields", "[1"), @image)
    end
  end

  test "redact/2 keeps the request without the image's bytes" do
    {:ok, body} = Client.request_body(@variant, @image)
    redacted = Client.redact(body, "us.anthropic.claude-sonnet-4-6")

    assert redacted["modelId"] == "us.anthropic.claude-sonnet-4-6"
    assert [%{"content" => [%{"image" => image}, %{"text" => _}]}] = redacted["messages"]
    assert image["source"]["bytes"] == "<image bytes omitted>"
  end
end
