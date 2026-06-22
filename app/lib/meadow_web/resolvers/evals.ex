defmodule MeadowWeb.Resolvers.Evals do
  @moduledoc "Absinthe resolvers for the evals feature."

  alias Meadow.Evals
  alias Meadow.Evals.Runner

  # ---------------------------------------------------------------------------
  # Eval Query resolvers
  # ---------------------------------------------------------------------------

  def list_eval_queries(_root, _args, _info), do: {:ok, Evals.list_eval_queries()}

  def default_eval_query(_root, _args, _info), do: {:ok, Evals.default_eval_query()}

  def create_eval_query(_root, args, %{context: %{current_user: user}}) do
    Evals.create_eval_query(Map.put(args, :author, user.email))
  end

  def update_eval_query(_root, %{id: id} = args, _info) do
    eval_query = Evals.get_eval_query!(id)
    Evals.update_eval_query(eval_query, Map.delete(args, :id))
  end

  def delete_eval_query(_root, %{id: id}, _info) do
    eval_query = Evals.get_eval_query!(id)
    Evals.delete_eval_query(eval_query)
  end

  # ---------------------------------------------------------------------------
  # Prompt version resolvers
  # ---------------------------------------------------------------------------

  def list_prompt_versions(_root, _args, _info), do: {:ok, Evals.list_active_prompt_versions()}

  def create_prompt_version(_root, args, %{context: %{current_user: user}}) do
    Evals.create_prompt_version(Map.put(args, :author, user.email))
  end

  def archive_prompt_version(_root, %{id: id}, _info) do
    pv = Evals.get_prompt_version!(id)
    Evals.archive_prompt_version(pv)
  end

  # ---------------------------------------------------------------------------
  # Eval set resolvers
  # ---------------------------------------------------------------------------

  def list_eval_sets(_root, _args, _info), do: {:ok, Evals.list_eval_sets()}

  def get_eval_set(_root, %{id: id}, _info) do
    {:ok, Evals.get_eval_set!(id)}
  rescue
    Ecto.NoResultsError -> {:error, "Eval set not found"}
  end

  def create_eval_set_from_work_ids(_root, %{work_ids: ids} = args, %{
        context: %{current_user: user}
      }) do
    set_attrs =
      args
      |> Map.delete(:work_ids)
      |> Map.put(:author, user.email)

    case Evals.create_eval_set_from_work_ids(ids, set_attrs) do
      {:ok, set, _skipped} -> {:ok, set}
      {:error, reason} -> {:error, inspect(reason)}
    end
  end

  def create_eval_set(_root, %{query_id: query_id} = args, %{context: %{current_user: user}}) do
    eval_query = Evals.get_eval_query!(query_id)

    set_attrs =
      args
      |> Map.delete(:query_id)
      |> Map.put(:author, user.email)

    case Evals.create_eval_set_from_query(eval_query, set_attrs) do
      {:ok, set, _skipped} -> {:ok, set}
      {:error, reason} -> {:error, inspect(reason)}
    end
  end

  # ---------------------------------------------------------------------------
  # Run resolvers
  # ---------------------------------------------------------------------------

  def list_runs(_root, args, _info) do
    opts = [
      limit: Map.get(args, :limit, 50),
      offset: Map.get(args, :offset, 0)
    ]

    {:ok, Evals.list_runs(opts)}
  end

  def get_run(_root, %{id: id}, _info) do
    {:ok, Evals.get_run!(id)}
  rescue
    Ecto.NoResultsError -> {:error, "Eval run not found"}
  end

  def create_run(_root, args, %{context: %{current_user: user}}) do
    run_attrs = Map.put(args, :author, user.email)

    case Evals.create_run(run_attrs) do
      {:ok, run} ->
        Runner.start(run.id)
        {:ok, run}

      {:error, changeset} ->
        {:error, format_errors(changeset)}
    end
  end

  def cancel_run(_root, %{id: id}, _info) do
    case Evals.cancel_run(id) do
      {:ok, run} -> {:ok, run}
      {:error, reason} -> {:error, inspect(reason)}
    end
  end

  def run_summary(run, _args, %{context: %{current_user: user}}) do
    {:ok, Evals.run_summary(run, user.email)}
  end

  def run_summary(run, _args, _info) do
    {:ok, Evals.run_summary(run, nil)}
  end

  # ---------------------------------------------------------------------------
  # Trial resolvers
  # ---------------------------------------------------------------------------

  def score_trial(_root, %{id: id, score: score} = args, %{context: %{current_user: user}}) do
    notes = Map.get(args, :notes)

    case Evals.score_trial(id, score, notes, user.email) do
      {:ok, trial} -> {:ok, trial}
      {:error, changeset} -> {:error, format_errors(changeset)}
    end
  end

  def clear_trial_score(_root, %{id: id}, %{context: %{current_user: user}}) do
    Evals.clear_trial_score(id, user.email)
  end

  # ---------------------------------------------------------------------------
  # Per-user trial score field resolvers
  #
  # Manual scores are per-user: these expose only the *current* user's score,
  # so the UI never reveals what other scorers chose.
  # ---------------------------------------------------------------------------

  def trial_manual_score(trial, _args, %{context: %{current_user: user}}) do
    {:ok, Evals.user_score(trial, user.email) || :unscored}
  end

  def trial_manual_score(_trial, _args, _info), do: {:ok, :unscored}

  def trial_manual_notes(trial, _args, %{context: %{current_user: user}}) do
    {:ok, with(%{notes: notes} <- Evals.user_score_record(trial, user.email), do: notes)}
  end

  def trial_manual_notes(_trial, _args, _info), do: {:ok, nil}

  def trial_manual_scored_by(trial, _args, %{context: %{current_user: user}}) do
    {:ok, with(%{scored_by: by} <- Evals.user_score_record(trial, user.email), do: by)}
  end

  def trial_manual_scored_by(_trial, _args, _info), do: {:ok, nil}

  def trial_manual_scored_at(trial, _args, %{context: %{current_user: user}}) do
    {:ok, with(%{scored_at: at} <- Evals.user_score_record(trial, user.email), do: at)}
  end

  def trial_manual_scored_at(_trial, _args, _info), do: {:ok, nil}

  # ---------------------------------------------------------------------------
  # Helpers
  # ---------------------------------------------------------------------------

  defp format_errors(%Ecto.Changeset{} = changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, _opts} -> msg end)
    |> Enum.map_join("; ", fn {k, v} -> "#{k}: #{Enum.join(v, ", ")}" end)
  end

  defp format_errors(other), do: inspect(other)
end
