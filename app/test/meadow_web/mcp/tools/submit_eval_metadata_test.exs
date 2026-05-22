defmodule MeadowWeb.MCP.Tools.SubmitEvalMetadataTest do
  use Meadow.DataCase, async: true

  alias Meadow.Evals
  alias Meadow.Evals.Schemas.{EvalSetMember, EvalSet}
  alias Meadow.Repo
  alias MeadowWeb.MCP.Tools.SubmitEvalMetadata

  describe "execute/2" do
    test "writes agent_output to the trial row" do
      trial = setup_trial()
      frame = %Anubis.Server.Frame{}

      args = %{
        trial_id: trial.id,
        description: "A photograph of folk dancers at the festival.",
        subjects: [
          %{id: "http://id.worldcat.org/fast/928794", label: "Folk dancing"},
          %{id: "http://id.worldcat.org/fast/856724", label: "Festivals"}
        ]
      }

      assert {:reply, _response, _frame} = SubmitEvalMetadata.execute(args, frame)

      updated = Evals.get_trial!(trial.id)
      assert updated.agent_output["description"] == "A photograph of folk dancers at the festival."
      assert length(updated.agent_output["subjects"]) == 2
    end

    test "returns error for unknown trial_id" do
      frame = %Anubis.Server.Frame{}

      args = %{
        trial_id: Ecto.UUID.generate(),
        description: "Test",
        subjects: []
      }

      assert {:error, _reason, _frame} = SubmitEvalMetadata.execute(args, frame)
    end
  end

  defp setup_trial do
    work_id = Ecto.UUID.generate()

    {:ok, query} = Evals.create_eval_query(%{
      name: "test-#{System.unique_integer()}",
      query_json: %{"query" => %{"match_all" => %{}}},
      author: "test"
    })

    set = Repo.insert!(%EvalSet{
      name: "test-set-#{System.unique_integer()}",
      query_id: query.id,
      work_count: 1
    })

    Repo.insert!(%EvalSetMember{
      eval_set_id: set.id,
      work_id: work_id,
      accession_number: "TEST.001",
      ground_truth: %{description: [], subjects: []}
    })

    {:ok, prompt} = Evals.create_prompt_version(%{
      name: "test-prompt-#{System.unique_integer()}",
      system_prompt: "test",
      user_prompt_template: "test {trial_id}",
      author: "test"
    })

    {:ok, run} = Evals.create_run(%{
      eval_set_id: set.id,
      prompt_version_id: prompt.id,
      trials_per_work: 1,
      author: "test"
    })

    Evals.list_trials_for_run(run.id) |> List.first()
  end
end
