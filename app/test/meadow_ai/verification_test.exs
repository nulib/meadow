defmodule MeadowAI.VerificationTest do
  use ExUnit.Case, async: true

  describe "verify_claude/1" do
    test "returns ok when Claude Code SDK is properly installed" do
      assert {:ok, :claude_sdk_verified} = MeadowAI.Verification.verify_claude()
    end

    test "returns error when Claude Code SDK is not properly installed" do
      assert {:error, {"CLINotFoundError", error}} =
               MeadowAI.Verification.verify_claude(cli_path: "/invalid/path")

      assert String.contains?(error, "Claude Code not found")
      assert String.contains?(error, "/invalid/path")
    end
  end

  describe "verify_claude_and_exit/1" do
    test "exits normally when Claude Code SDK is properly installed" do
      assert :normal = catch_exit(MeadowAI.Verification.verify_claude_and_exit())
    end

    test "exits with shutdown when Claude Code SDK is not properly installed" do
      assert {:shutdown, 1} =
               catch_exit(MeadowAI.Verification.verify_claude_and_exit(cli_path: "/invalid/path"))
    end
  end
end
