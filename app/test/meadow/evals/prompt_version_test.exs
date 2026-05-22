defmodule Meadow.Evals.PromptVersionTest do
  use Meadow.DataCase

  alias Meadow.Evals

  describe "create_prompt_version/1" do
    test "assembles internal prompts from editable task prompts" do
      {:ok, prompt_version} =
        Evals.create_prompt_version(%{
          name: "task-prompt-#{System.unique_integer()}",
          subject_prompt: "Find LCNAF names and FAST topics.",
          description_prompt: "Write one sentence for catalog display.",
          author: "test"
        })

      assert prompt_version.subject_prompt == "Find LCNAF names and FAST topics."
      assert prompt_version.description_prompt == "Write one sentence for catalog display."
      assert prompt_version.system_prompt == Evals.default_eval_system_prompt()
      assert prompt_version.user_prompt_template =~ "2. Find LCNAF names and FAST topics."
      assert prompt_version.user_prompt_template =~ "3. Write one sentence for catalog display."
      assert prompt_version.user_prompt_template =~ "mcp__meadow__submit_eval_metadata"
    end

    test "still accepts explicitly assembled prompts" do
      {:ok, prompt_version} =
        Evals.create_prompt_version(%{
          name: "legacy-prompt-#{System.unique_integer()}",
          system_prompt: "You are a test agent.",
          user_prompt_template: "Analyze work {work_id}.",
          author: "test"
        })

      assert prompt_version.system_prompt == "You are a test agent."
      assert prompt_version.user_prompt_template == "Analyze work {work_id}."
    end
  end
end
