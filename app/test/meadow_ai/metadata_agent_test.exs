defmodule MeadowAI.MetadataAgentTest do
  use ExUnit.Case, async: false

  alias Meadow.Utils.Lambda
  alias MeadowAI.MetadataAgent

  describe "query/2" do
    setup do
      start_supervised!(MetadataAgent)
      start_supervised!({Task.Supervisor, name: MeadowAI.MetadataAgent.TaskSupervisor})
      :ok
    end

    test "test queries return expected responses" do
      prompt = "Test prompt"

      # Success
      assert {:ok, %{request_count: 0, failure_count: 0, last_failure: nil}} =
               MetadataAgent.status()

      assert {:ok, {%{"result" => "test"}, ^prompt, opts}} =
               MetadataAgent.query(prompt, test: true, timeout: 1_000)

      assert opts[:test] == true
      assert Keyword.has_key?(opts, :firewall_security_header)
      assert Keyword.has_key?(opts, :auth_token)
      assert Keyword.has_key?(opts, :mcp_url)

      assert {:ok, %{request_count: 1, failure_count: 0, last_failure: nil}} =
               MetadataAgent.status()

      # Failure
      assert {:error, :timeout} = MetadataAgent.query(prompt, test: true, timeout: 250)

      assert {:ok, %{request_count: 2, failure_count: 1, last_failure: %DateTime{}}} =
               MetadataAgent.status()
    end
  end

  describe "query/2 against the metadataAgent lambda" do
    setup do
      start_supervised!(MetadataAgent)
      start_supervised!({Task.Supervisor, name: MeadowAI.MetadataAgent.TaskSupervisor})

      script = Path.expand("./test/fixtures/lambda/index")
      lambda_config = {:local, {script, "metadataAgentHandler"}}
      original = Application.get_env(:meadow, :lambda, [])

      Application.put_env(
        :meadow,
        :lambda,
        Keyword.put(original, :metadataAgent, lambda_config)
      )

      on_exit(fn ->
        Lambda.close(lambda_config)
        Application.put_env(:meadow, :lambda, original)
      end)

      :ok
    end

    test "unwraps the result from a successful {statusCode, body} response" do
      assert {:ok, response} =
               MetadataAgent.query("Improve the title", context: %{test: "success"})

      assert %{"result" => "Processed: Improve the title", "total_cost_usd" => 0.25} = response
      refute Map.has_key?(response, "usage")

      assert {:ok, %{request_count: 1, failure_count: 0}} = MetadataAgent.status()
    end

    test "sends the auth token and firewall security header to the lambda" do
      assert {:ok, %{"result" => %{"Authorization" => "Bearer " <> _} = headers}} =
               MetadataAgent.query("Improve the title", context: %{test: "echo_headers"})

      assert map_size(headers) == 1

      assert {:ok, %{"result" => %{"Authorization" => "Bearer " <> _, "X-Firewall" => "secret"}}} =
               MetadataAgent.query("Improve the title",
                 context: %{test: "echo_headers"},
                 firewall_security_header: [value: "secret", name: "X-Firewall"]
               )
    end

    test "returns an error for a non-200 statusCode" do
      assert {:error, {:lambda_invocation_failed, 500, "Something went wrong"}} =
               MetadataAgent.query("Improve the title", context: %{test: "error_status"})

      assert {:ok, %{failure_count: 1}} = MetadataAgent.status()
    end

    test "returns an error when the lambda reports an errorMessage" do
      assert {:error, {:lambda_invocation_failed, "Task timed out after 900.00 seconds"}} =
               MetadataAgent.query("Improve the title", context: %{test: "error_message"})
    end

    test "returns an error when the body is not valid JSON" do
      assert {:error, {:invalid_response, {:error, %Jason.DecodeError{}}}} =
               MetadataAgent.query("Improve the title", context: %{test: "invalid_json"})
    end

    test "rejects prompts over 10,000 characters" do
      assert {:error, {:input_too_large, _}} =
               MetadataAgent.query(String.duplicate("x", 10_001), context: %{test: "success"})
    end
  end
end
