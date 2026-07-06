defmodule Meadow.EvalsTest do
  use Meadow.DataCase

  alias Meadow.Evals
  alias Meadow.Evals.Schemas.{EvalRun, EvalSet, EvalSetMember, EvalTrial, EvalTrialScore}
  alias Meadow.Repo

  import Meadow.TestHelpers

  describe "resolve_identifiers/1" do
    test "resolves work UUIDs as-is" do
      work_id = Ecto.UUID.generate()
      assert Evals.resolve_identifiers([work_id]) == [work_id]
    end

    test "resolves accession numbers to work ids" do
      work = work_fixture(%{accession_number: "TEST.ACC.001"})
      assert Evals.resolve_identifiers(["TEST.ACC.001"]) == [work.id]
    end

    test "resolves a mix of work UUIDs and accession numbers, dropping unknowns" do
      work = work_fixture(%{accession_number: "TEST.ACC.002"})
      other_work_id = Ecto.UUID.generate()

      result =
        Evals.resolve_identifiers([
          other_work_id,
          "TEST.ACC.002",
          "no-such-accession"
        ])

      assert Enum.sort(result) == Enum.sort([other_work_id, work.id])
    end

    test "deduplicates resolved ids" do
      work = work_fixture(%{accession_number: "TEST.ACC.003"})
      assert Evals.resolve_identifiers([work.id, "TEST.ACC.003"]) == [work.id]
    end
  end

  describe "delete_run/1" do
    test "deletes a run and cascades trials and scores" do
      {run, trials} = setup_run_with_trial()
      [trial] = trials

      {:ok, _score} =
        %EvalTrialScore{}
        |> EvalTrialScore.changeset(%{
          eval_trial_id: trial.id,
          scored_by: "test@example.com",
          score: :good
        })
        |> Repo.insert()

      assert {:ok, _} = Evals.delete_run(run.id)

      assert Repo.get(EvalRun, run.id) == nil
      assert Repo.get(EvalTrial, trial.id) == nil
      assert Repo.all(from(s in EvalTrialScore, where: s.eval_trial_id == ^trial.id)) == []
    end
  end

  describe "MeadowWeb.Resolvers.Evals.delete_run/3" do
    alias MeadowWeb.Resolvers.Evals, as: EvalsResolver

    test "refuses to delete a pending run" do
      {run, _trials} = setup_run_with_trial()
      assert {:error, message} = EvalsResolver.delete_run(nil, %{id: run.id}, %{})
      assert message =~ "pending"
      assert Repo.get(EvalRun, run.id)
    end

    test "refuses to delete a running run" do
      {run, _trials} = setup_run_with_trial()
      {:ok, run} = run |> EvalRun.mark_running() |> Repo.update()

      assert {:error, message} = EvalsResolver.delete_run(nil, %{id: run.id}, %{})
      assert message =~ "running"
      assert Repo.get(EvalRun, run.id)
    end

    test "allows deleting a complete run" do
      {run, _trials} = setup_run_with_trial()
      {:ok, run} = run |> EvalRun.mark_complete() |> Repo.update()

      assert {:ok, deleted} = EvalsResolver.delete_run(nil, %{id: run.id}, %{})
      assert deleted.id == run.id
      assert Repo.get(EvalRun, run.id) == nil
    end

    test "allows deleting an errored run" do
      {run, _trials} = setup_run_with_trial()
      {:ok, run} = run |> EvalRun.mark_errored("boom") |> Repo.update()

      assert {:ok, deleted} = EvalsResolver.delete_run(nil, %{id: run.id}, %{})
      assert deleted.id == run.id
      assert Repo.get(EvalRun, run.id) == nil
    end

    test "allows deleting a cancelled run" do
      {run, _trials} = setup_run_with_trial()
      {:ok, run} = run |> EvalRun.mark_cancelled() |> Repo.update()

      assert {:ok, deleted} = EvalsResolver.delete_run(nil, %{id: run.id}, %{})
      assert deleted.id == run.id
      assert Repo.get(EvalRun, run.id) == nil
    end
  end

  defp setup_run_with_trial do
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
        user_prompt_template: "Analyze work {work_id}, trial {trial_id}.",
        author: "test"
      })

    work_id = Ecto.UUID.generate()

    eval_set =
      Repo.insert!(%EvalSet{
        name: "test-set-#{System.unique_integer()}",
        query_id: eval_query.id,
        work_count: 1
      })

    Repo.insert!(%EvalSetMember{
      eval_set_id: eval_set.id,
      work_id: work_id,
      accession_number: "TEST.001",
      ground_truth: %{description: ["test description"], subjects: [%{id: "http://id.worldcat.org/fast/1"}]}
    })

    {:ok, run} =
      Evals.create_run(%{
        eval_set_id: eval_set.id,
        prompt_version_id: prompt_version.id,
        trials_per_work: 1,
        author: "test"
      })

    trials = Evals.list_trials_for_run(run.id)
    {run, trials}
  end
end
