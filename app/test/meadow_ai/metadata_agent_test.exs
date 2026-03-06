defmodule MeadowAI.MetadataAgentTest do
  use ExUnit.Case, async: true

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
      assert {:ok, %{request_count: 0, failure_count: 0, last_failure: nil}} = MetadataAgent.status()
      assert {:ok, {"test", ^prompt, opts}} = MetadataAgent.query(prompt, test: true, timeout: 1_000)
      assert opts[:test] == true
      assert Keyword.has_key?(opts, :firewall_security_header)
      assert Keyword.has_key?(opts, :auth_token)
      assert Keyword.has_key?(opts, :mcp_url)
      assert {:ok, %{request_count: 1, failure_count: 0, last_failure: nil}} = MetadataAgent.status()

      # Failure
      assert {:error, :timeout} = MetadataAgent.query(prompt, test: true, timeout: 250)

      assert {:ok, %{request_count: 2, failure_count: 1, last_failure: %DateTime{}}} =
               MetadataAgent.status()
    end
  end
end
