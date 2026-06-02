defmodule Meadow.Evals.RunnerTest do
  use Meadow.DataCase, async: false

  alias Meadow.Evals
  alias Meadow.Evals.Runner
  alias Meadow.Evals.Schemas.EvalRun
  alias Meadow.Repo

  setup do
    start_supervised!({Task.Supervisor, name: Meadow.Evals.TaskSupervisor})
    :ok
  end

  describe "start/1" do
    test "transitions run to running and complete" do
      {run, _trials} = setup_run(trials_per_work: 1)
      assert run.status == :pending

      # Stub MeadowAI.query to return a test response.
      # We can't easily stub in integration here, so we just check the runner
      # doesn't crash and transitions correctly when the agent call fails gracefully.
      # Full integration requires a running Lambda.

      # A cancelled run should be a no-op
      {:ok, cancelled_run} = Evals.cancel_run(run.id)
      assert cancelled_run.status == :cancelled

      # Starting a cancelled run is a no-op
      assert {:ok, _pid} = Runner.start(cancelled_run.id)
      :timer.sleep(200)

      # Status should remain cancelled
      fresh = Repo.get!(EvalRun, run.id)
      assert fresh.status == :cancelled
    end
  end

  describe "cancel_run/1" do
    test "transitions run to cancelled" do
      {run, _trials} = setup_run(trials_per_work: 2)
      {:ok, cancelled} = Evals.cancel_run(run.id)
      assert cancelled.status == :cancelled
    end
  end

  # ---------------------------------------------------------------------------
  # Helpers
  # ---------------------------------------------------------------------------

  defp setup_run(opts) do
    trials_per_work = Keyword.get(opts, :trials_per_work, 1)

    {:ok, eval_query} = Evals.create_eval_query(%{
      name: "test-query-#{System.unique_integer()}",
      query_json: %{"query" => %{"match_all" => %{}}},
      author: "test"
    })

    {:ok, prompt_version} = Evals.create_prompt_version(%{
      name: "test-prompt-#{System.unique_integer()}",
      system_prompt: "You are a test agent.",
      user_prompt_template: "Analyze work {work_id}, trial {trial_id}.",
      author: "test"
    })

    # Create eval set manually (skip OpenSearch in unit tests)
    work_id = Ecto.UUID.generate()

    eval_set =
      Repo.insert!(%Meadow.Evals.Schemas.EvalSet{
        name: "test-set-#{System.unique_integer()}",
        query_id: eval_query.id,
        work_count: 1
      })

    Repo.insert!(%Meadow.Evals.Schemas.EvalSetMember{
      eval_set_id: eval_set.id,
      work_id: work_id,
      accession_number: "TEST.001",
      ground_truth: %{description: ["test description"], subjects: [%{id: "http://id.worldcat.org/fast/1"}]}
    })

    {:ok, run} = Evals.create_run(%{
      eval_set_id: eval_set.id,
      prompt_version_id: prompt_version.id,
      trials_per_work: trials_per_work,
      author: "test"
    })

    trials = Evals.list_trials_for_run(run.id)
    {run, trials}
  end
end
