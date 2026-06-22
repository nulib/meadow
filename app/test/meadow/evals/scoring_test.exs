defmodule Meadow.Evals.ScoringTest do
  use Meadow.DataCase, async: false

  alias Meadow.Evals
  alias Meadow.Evals.Schemas.{EvalSet, EvalSetMember, EvalTrial}
  alias Meadow.Repo

  @alice "alice@example.com"
  @bob "bob@example.com"

  setup do
    {:ok, eval_query} =
      Evals.create_eval_query(%{
        name: "test-query-#{System.unique_integer()}",
        query_json: %{"query" => %{"match_all" => %{}}},
        author: "test"
      })

    {:ok, prompt_version} =
      Evals.create_prompt_version(%{
        name: "test-prompt-#{System.unique_integer()}",
        system_prompt: "You are a test agent.",
        user_prompt_template: "Analyze {work_id}.",
        author: "test"
      })

    eval_set =
      Repo.insert!(%EvalSet{
        name: "test-set-#{System.unique_integer()}",
        query_id: eval_query.id,
        work_count: 1
      })

    Repo.insert!(%EvalSetMember{
      eval_set_id: eval_set.id,
      work_id: Ecto.UUID.generate(),
      accession_number: "TEST.001",
      ground_truth: %{description: ["a description"], subjects: []}
    })

    {:ok, run} =
      Evals.create_run(%{
        eval_set_id: eval_set.id,
        prompt_version_id: prompt_version.id,
        trials_per_work: 1,
        author: "test"
      })

    [trial] = Evals.list_trials_for_run(run.id)
    %{run: run, trial: trial}
  end

  describe "score_trial/4 (per-user)" do
    test "two users score the same trial independently", %{trial: trial} do
      {:ok, _} = Evals.score_trial(trial.id, :good, "looks right", @alice)
      {:ok, _} = Evals.score_trial(trial.id, :bad, "missing subjects", @bob)

      reloaded = EvalTrial |> Repo.get!(trial.id) |> Repo.preload(:scores)
      assert length(reloaded.scores) == 2

      assert Evals.user_score(reloaded, @alice) == :good
      assert Evals.user_score(reloaded, @bob) == :bad
      assert Evals.user_score_record(reloaded, @alice).notes == "looks right"
      assert Evals.user_score_record(reloaded, @bob).notes == "missing subjects"
    end

    test "re-scoring upserts the same user's row", %{trial: trial} do
      {:ok, _} = Evals.score_trial(trial.id, :good, "first", @alice)
      {:ok, _} = Evals.score_trial(trial.id, :bad, "changed my mind", @alice)

      reloaded = EvalTrial |> Repo.get!(trial.id) |> Repo.preload(:scores)
      assert length(reloaded.scores) == 1
      assert Evals.user_score(reloaded, @alice) == :bad
      assert Evals.user_score_record(reloaded, @alice).notes == "changed my mind"
    end

    test "a user with no score reads as nil", %{trial: trial} do
      {:ok, _} = Evals.score_trial(trial.id, :good, nil, @alice)
      reloaded = EvalTrial |> Repo.get!(trial.id) |> Repo.preload(:scores)
      assert Evals.user_score(reloaded, @bob) == nil
      assert Evals.user_score_record(reloaded, @bob) == nil
    end
  end

  describe "clear_trial_score/2" do
    test "removes only the calling user's score", %{trial: trial} do
      {:ok, _} = Evals.score_trial(trial.id, :good, nil, @alice)
      {:ok, _} = Evals.score_trial(trial.id, :bad, nil, @bob)

      {:ok, _} = Evals.clear_trial_score(trial.id, @alice)

      reloaded = EvalTrial |> Repo.get!(trial.id) |> Repo.preload(:scores)
      assert Evals.user_score(reloaded, @alice) == nil
      assert Evals.user_score(reloaded, @bob) == :bad
    end
  end

  describe "run_summary/2 (per-user counts)" do
    test "good/bad counts are scoped to the given user", %{run: run, trial: trial} do
      {:ok, _} = Evals.score_trial(trial.id, :good, nil, @alice)
      {:ok, _} = Evals.score_trial(trial.id, :bad, nil, @bob)

      alice_summary = Evals.run_summary(run, @alice)
      assert alice_summary.manual_good == 1
      assert alice_summary.manual_bad == 0

      bob_summary = Evals.run_summary(run, @bob)
      assert bob_summary.manual_good == 0
      assert bob_summary.manual_bad == 1

      anon_summary = Evals.run_summary(run, nil)
      assert anon_summary.manual_good == 0
      assert anon_summary.manual_bad == 0
    end

    test "nil judge scores are excluded from the means", %{run: run, trial: trial} do
      trial
      |> Ecto.Changeset.change(%{
        status: :complete,
        description_judge_score: nil,
        subjects_judge_score: 0.8
      })
      |> Repo.update!()

      summary = Evals.run_summary(run, @alice)
      assert summary.mean_description_judge_score == nil
      assert summary.mean_subjects_judge_score == 0.8
    end
  end
end
