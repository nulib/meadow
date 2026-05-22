defmodule MeadowAI.MetadataAgentTest do
  use ExUnit.Case, async: false

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

    test "test queries rewrite localhost MCP URLs for SAM lambdas" do
      System.put_env("USE_SAM_LAMBDAS", "true")
      System.put_env("MEADOW_SAM_HOST_URL", "http://host.docker.internal")

      on_exit(fn ->
        System.delete_env("USE_SAM_LAMBDAS")
        System.delete_env("MEADOW_SAM_HOST_URL")
      end)

      prompt = "Test prompt"

      assert {:ok, {%{"result" => "test"}, ^prompt, opts}} =
               MetadataAgent.query(prompt,
                 test: true,
                 timeout: 1_000,
                 mcp_url: "http://localhost:4000/api/mcp/eval"
               )

      assert opts[:mcp_url] == "http://host.docker.internal:4000/api/mcp/eval"
    end

    test "test queries rewrite generated external MCP URLs for SAM lambdas" do
      System.put_env("USE_SAM_LAMBDAS", "true")
      System.delete_env("MEADOW_SAM_HOST_URL")

      on_exit(fn ->
        System.delete_env("USE_SAM_LAMBDAS")
        System.delete_env("MEADOW_SAM_HOST_URL")
      end)

      prompt = "Test prompt"

      assert {:ok, {%{"result" => "test"}, ^prompt, opts}} =
               MetadataAgent.query(prompt,
                 test: true,
                 timeout: 1_000,
                 mcp_url: "https://bmq.dev.rdc.library.northwestern.edu:3001/api/mcp/eval"
               )

      assert opts[:mcp_url] == "http://172.17.0.1:4000/api/mcp/eval"
    end
  end
end
