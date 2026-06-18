defmodule Meadow.Evals.Runner do
  @moduledoc "Executes an EvalRun by dispatching agent calls for each trial."

  require Logger

  import Ecto.Query
  alias Meadow.{Evals, Repo}
  alias Meadow.Evals.{Judge, Schemas.EvalRun, Schemas.EvalTrial}
  alias MeadowWeb.Router.Helpers, as: Routes

  @doc """
  Start execution of a run in a supervised background task.
  Idempotent: if the run is already running or complete, this is a no-op.
  """
  def start(run_id) when is_binary(run_id) do
    Task.Supervisor.start_child(
      Meadow.Evals.TaskSupervisor,
      fn -> execute(run_id) end,
      restart: :temporary
    )
  end

  # ---------------------------------------------------------------------------
  # Private execution logic
  # ---------------------------------------------------------------------------

  defp execute(run_id) do
    run = Evals.get_run!(run_id)

    if run.status in [:pending, :running] do
      run
      |> EvalRun.mark_running()
      |> Repo.update!()

      Logger.info("Evals.Runner: starting run #{run_id} (#{length(run.eval_trials)} trials)")

      try do
        execute_trials(run)
        run = Repo.get!(EvalRun, run_id)
        run |> EvalRun.mark_complete() |> Repo.update!()
        Logger.info("Evals.Runner: run #{run_id} complete")
      rescue
        error ->
          Logger.error("Evals.Runner: run #{run_id} failed: #{Exception.message(error)}")

          Repo.get!(EvalRun, run_id)
          |> EvalRun.mark_errored(Exception.message(error))
          |> Repo.update!()
      end
    else
      Logger.info("Evals.Runner: run #{run_id} already #{run.status}, skipping")
      :ok
    end
  end

  defp execute_trials(run) do
    set = Evals.get_eval_set!(run.eval_set_id)
    prompt_version = Evals.get_prompt_version!(run.prompt_version_id)
    concurrency = run.concurrency || 3

    # Build (member, trial_index) pairs for all pending trials
    work_map = Map.new(set.eval_set_members, &{&1.work_id, &1})

    pending_trials =
      from(t in EvalTrial,
        where: t.eval_run_id == ^run.id and t.status == :pending,
        order_by: [asc: t.work_id, asc: t.trial_index]
      )
      |> Repo.all()

    pending_trials
    |> Task.async_stream(
      fn trial ->
        member = Map.get(work_map, trial.work_id)

        if halted?(run.id) do
          :halted
        else
          execute_trial(run, trial, member, prompt_version)
        end
      end,
      max_concurrency: concurrency,
      timeout: :infinity,
      on_timeout: :kill_task
    )
    |> Stream.run()
  end

  defp halted?(run_id) do
    case Repo.get(EvalRun, run_id) do
      %EvalRun{status: status} when status in [:cancelled, :errored] -> true
      _ -> false
    end
  end

  defp execute_trial(run, trial, member, prompt_version) do
    do_execute_trial(run, trial, member, prompt_version)
  end

  defp do_execute_trial(run, trial, member, prompt_version) do
    trial |> EvalTrial.mark_running() |> Repo.update!()

    mcp_url = Routes.page_url(MeadowWeb.Endpoint, :index, ["api", "mcp", "eval"])

    prompt =
      prompt_version.user_prompt_template
      |> render_prompt(%{
        work_id: trial.work_id,
        trial_id: trial.id,
        file_set_id: member && member.representative_file_set_id,
        accession_number: member && member.accession_number
      })
      |> Evals.eval_tool_prompt()

    context = %{
      system_prompt: Evals.eval_system_prompt(prompt_version.system_prompt),
      eval: true,
      run_id: run.id,
      trial_id: trial.id,
      work_id: trial.work_id
    }

    started_at = System.monotonic_time(:millisecond)

    result = MeadowAI.query(prompt, mcp_url: mcp_url, context: context)

    duration_ms = System.monotonic_time(:millisecond) - started_at

    case result do
      {:ok, response} ->
        handle_agent_response(trial, member, prompt, duration_ms, response)

      {:error, reason} ->
        Logger.error("Evals.Runner: trial #{trial.id} failed: #{inspect(reason)}")

        trial |> EvalTrial.mark_errored(inspect(reason)) |> Repo.update!()
    end
  end

  defp handle_agent_response(trial, member, prompt, duration_ms, response) do
    # Reload trial to get agent_output written by SubmitEvalMetadata
    fresh_trial = Evals.get_trial!(trial.id)

    if missing_agent_output?(fresh_trial.agent_output) do
      fresh_trial
      |> EvalTrial.mark_errored("Agent completed without calling submit_eval_metadata")
      |> Repo.update!()
    else
      complete_trial(fresh_trial, member, prompt, duration_ms, response)
    end
  end

  defp complete_trial(trial, member, prompt, duration_ms, response) do
    judge = judge_scores(trial, member)

    trial
    |> EvalTrial.mark_complete(%{
      transcript: %{
        result: Map.get(response, "result"),
        model: Map.get(response, "model"),
        prompt: prompt
      },
      duration_ms: duration_ms,
      description_judge_score: judge.description_judge_score,
      subjects_judge_score: judge.subjects_judge_score,
      judge_rationale: judge.judge_rationale
    })
    |> Repo.update!()
  end

  defp judge_scores(trial, member) do
    ground_truth = (member && member.ground_truth) || %{}
    file_set_id = member && member.representative_file_set_id

    case Judge.score(trial.agent_output, ground_truth, file_set_id: file_set_id) do
      {:ok, scores} ->
        scores

      {:error, reason} ->
        Logger.warning(
          "Evals.Runner: judge scoring failed for trial #{trial.id}: #{inspect(reason)}"
        )

        %{
          description_judge_score: nil,
          subjects_judge_score: nil,
          judge_rationale: nil
        }
    end
  end

  defp render_prompt(template, assigns) do
    Enum.reduce(assigns, template, fn {key, value}, acc ->
      String.replace(acc, "{#{key}}", to_string(value || ""))
    end)
  end

  defp missing_agent_output?(nil), do: true
  defp missing_agent_output?(output) when output == %{}, do: true
  defp missing_agent_output?(_), do: false
end
