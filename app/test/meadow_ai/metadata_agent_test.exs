defmodule MeadowAI.MetadataAgentTest do
  use ExUnit.Case, async: true

  describe "init/1" do
    setup do
      start_supervised!({MeadowAI.MetadataAgent, []})
      :ok
    end

    test "properly initializes the Pythonx environment" do
      {result, _} = Pythonx.eval("import os; os.getenv('CLAUDE_CODE_USE_BEDROCK')", %{})
      assert Pythonx.decode(result) == "1"
    end
  end
end
