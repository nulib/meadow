defmodule Meadow.Evals do
  @moduledoc "Context for the evals feature."

  import Ecto.Query
  alias Meadow.{Config, Repo}
  alias Meadow.Data.{Schemas.Work, Works}

  alias Meadow.Evals.Schemas.{
    EvalPromptVersion,
    EvalQuery,
    EvalRun,
    EvalSet,
    EvalSetMember,
    EvalTrial,
    EvalTrialScore
  }

  alias Meadow.Search.Config, as: SearchConfig
  alias Meadow.Search.Slice
  require Logger

  @max_works_per_set 20
  @default_eval_system_prompt """
  You are a digital library metadata specialist generating structured metadata for image works.
  Use the available tools to analyze the image, find appropriate subject headings, then call
  mcp__meadow__submit_eval_metadata to store the results. Do not return the results as text.
  """

  @default_subject_prompt """
  Find 3 appropriate subject headings
  based on what you see - people, places, events, topics, or objects in the image.
  Use authority_code: "lcnaf" for names and "fast" for everything else.
  """

  @default_description_prompt "Write a concise descriptive summary (1-3 sentences)."

  # ---------------------------------------------------------------------------
  # Eval Queries
  # ---------------------------------------------------------------------------

  def list_eval_queries do
    Repo.all(from q in EvalQuery, order_by: [asc: q.name])
  end

  def get_eval_query!(id), do: Repo.get!(EvalQuery, id)

  def get_eval_query_by_name(name), do: Repo.get_by(EvalQuery, name: name)

  def create_eval_query(attrs) do
    %EvalQuery{} |> EvalQuery.changeset(attrs) |> Repo.insert()
  end

  def update_eval_query(%EvalQuery{} = q, attrs) do
    q |> EvalQuery.changeset(attrs) |> Repo.update()
  end

  def delete_eval_query(%EvalQuery{} = q), do: Repo.delete(q)

  def default_eval_query do
    case Config.evals(:default_query_name) do
      nil -> nil
      name -> get_eval_query_by_name(name)
    end
  end

  # ---------------------------------------------------------------------------
  # Eval Prompt Versions
  # ---------------------------------------------------------------------------

  def list_prompt_versions do
    Repo.all(from pv in EvalPromptVersion, order_by: [desc: pv.inserted_at])
  end

  def list_active_prompt_versions do
    Repo.all(
      from pv in EvalPromptVersion, where: pv.archived == false, order_by: [desc: pv.inserted_at]
    )
  end

  def get_prompt_version!(id), do: Repo.get!(EvalPromptVersion, id)

  def create_prompt_version(attrs) do
    %EvalPromptVersion{}
    |> EvalPromptVersion.changeset(assemble_prompt_version(attrs))
    |> Repo.insert()
  end

  def archive_prompt_version(%EvalPromptVersion{} = pv) do
    pv |> EvalPromptVersion.archive() |> Repo.update()
  end

  def latest_prompt_version do
    Repo.one(
      from pv in EvalPromptVersion,
        where: pv.archived == false,
        order_by: [desc: pv.inserted_at],
        limit: 1
    )
  end

  def default_eval_system_prompt, do: String.trim(@default_eval_system_prompt)
  def default_subject_prompt, do: String.trim(@default_subject_prompt)
  def default_description_prompt, do: String.trim(@default_description_prompt)

  def eval_user_prompt_template(subject_prompt, description_prompt) do
    subject_prompt = prompt_task_text(subject_prompt, default_subject_prompt())
    description_prompt = prompt_task_text(description_prompt, default_description_prompt())

    """
    Analyze the following IMAGE work from a digital library collection.

    Work ID: {work_id}
    Trial ID: {trial_id}
    Accession Number: {accession_number}

    1. Call `mcp__meadow__get_iiif_image` with file_set_id: "{file_set_id}" to view the image.
    #{numbered_prompt_task(2, subject_prompt)}
    #{numbered_prompt_task(3, description_prompt)}
    4. Call `mcp__meadow__submit_eval_metadata` with:
       - trial_id: "{trial_id}"
       - description: your 1-3 sentence summary
       - subjects: array from mcp__meadow__authority_search results, each with id and label
    """
    |> String.trim()
  end

  defp assemble_prompt_version(attrs) do
    subject_prompt = prompt_attr(attrs, :subject_prompt)
    description_prompt = prompt_attr(attrs, :description_prompt)

    if present?(subject_prompt) or present?(description_prompt) do
      subject_prompt = prompt_task_text(subject_prompt, default_subject_prompt())
      description_prompt = prompt_task_text(description_prompt, default_description_prompt())

      attrs
      |> Map.put(:subject_prompt, subject_prompt)
      |> Map.put(:description_prompt, description_prompt)
      |> Map.put_new(:system_prompt, default_eval_system_prompt())
      |> Map.put_new(
        :user_prompt_template,
        eval_user_prompt_template(subject_prompt, description_prompt)
      )
    else
      attrs
    end
  end

  defp prompt_attr(attrs, key) do
    Map.get(attrs, key) || Map.get(attrs, Atom.to_string(key))
  end

  defp present?(value) when is_binary(value), do: String.trim(value) != ""
  defp present?(value), do: not is_nil(value)

  defp prompt_task_text(value, default) when is_binary(value) do
    case String.trim(value) do
      "" -> default
      trimmed -> trimmed
    end
  end

  defp prompt_task_text(_value, default), do: default

  defp numbered_prompt_task(number, text) do
    [first_line | remaining_lines] = String.split(text, "\n")

    ([to_string(number) <> ". " <> first_line] ++ Enum.map(remaining_lines, &("   " <> &1)))
    |> Enum.join("\n")
  end

  def eval_system_prompt(nil), do: nil

  def eval_system_prompt(system_prompt) do
    """
    #{eval_tool_prompt(system_prompt)}

    Eval runs use the IIIF-ready Meadow MCP tools. Use these exact tool names:
    - mcp__meadow__get_iiif_image
    - mcp__meadow__authority_search
    - mcp__meadow__submit_eval_metadata
    """
    |> String.trim()
  end

  def eval_tool_prompt(prompt) do
    prompt
    |> String.replace(
      ~r/(?<!mcp__meadow__)\bapply_work_metadata\b/,
      "mcp__meadow__submit_eval_metadata"
    )
    |> String.replace(
      ~r/(?<!mcp__meadow__)\bsubmit_eval_metadata\b/,
      "mcp__meadow__submit_eval_metadata"
    )
    |> String.replace(~r/(?<!mcp__meadow__)\bauthority_search\b/, "mcp__meadow__authority_search")
    |> String.replace(~r/(?<!mcp__meadow__)\bget_iiif_image\b/, "mcp__meadow__get_iiif_image")
    |> String.replace(~r/(?<!mcp__meadow__)\bget_image\b/, "mcp__meadow__get_iiif_image")
    |> String.replace(~r/\bmcp__meadow__mcp__meadow__/, "mcp__meadow__")
  end

  # ---------------------------------------------------------------------------
  # Eval Sets
  # ---------------------------------------------------------------------------

  def list_eval_sets do
    Repo.all(from es in EvalSet, order_by: [desc: es.inserted_at])
  end

  def get_eval_set!(id) do
    Repo.get!(EvalSet, id)
    |> Repo.preload([:eval_query, :eval_set_members])
  end

  @doc """
  Materialize a new EvalSet from a saved EvalQuery.

  Runs the query against OpenSearch, loads each matching Work, snapshots ground
  truth (description + subjects), and stores one EvalSetMember per work.
  Works with no description AND fewer than 3 subjects are skipped.
  Returns {:ok, eval_set, skipped_count} or {:error, reason}.
  """
  def create_eval_set_from_work_ids(work_ids, attrs) when is_list(work_ids) do
    query_json = %{"query" => %{"ids" => %{"values" => work_ids}}}
    transient = %EvalQuery{id: nil, query_json: query_json}
    create_eval_set_from_query(transient, attrs)
  end

  def create_eval_set_from_query(%EvalQuery{} = eval_query, attrs) do
    Logger.info("Evals: materializing set from query #{eval_query.id}")

    query_body =
      Map.merge(eval_query.query_json, %{"_source" => false, "fields" => [], "size" => 10_000})

    with {:ok, work_ids} <- fetch_work_ids(query_body),
         work_ids <- truncate_work_ids(work_ids),
         {members_attrs, skipped} <- build_members(work_ids),
         work_count <- length(members_attrs) do
      set_attrs =
        attrs
        |> Map.put(:query_id, eval_query.id)
        |> Map.put(:query_snapshot, eval_query.query_json)
        |> Map.put(:work_count, work_count)

      Repo.transaction(fn ->
        set = %EvalSet{} |> EvalSet.changeset(set_attrs) |> Repo.insert!()
        Enum.each(members_attrs, &insert_eval_set_member(&1, set.id))
        {set, skipped}
      end)
      |> case do
        {:ok, {set, skipped}} -> {:ok, set, skipped}
        {:error, reason} -> {:error, reason}
      end
    end
  end

  defp truncate_work_ids(work_ids) do
    if length(work_ids) > @max_works_per_set do
      Logger.info(
        "Evals: query returned #{length(work_ids)} works; truncating to #{@max_works_per_set}"
      )

      Enum.take(work_ids, @max_works_per_set)
    else
      work_ids
    end
  end

  defp insert_eval_set_member(member_attrs, eval_set_id) do
    %EvalSetMember{}
    |> EvalSetMember.changeset(Map.put(member_attrs, :eval_set_id, eval_set_id))
    |> Repo.insert!()
  end

  defp fetch_work_ids(query_body) do
    case Slice.paginate(query_body, SearchConfig.alias_for(Work, 2)) do
      {:error, reason} ->
        {:error, reason}

      slice ->
        ids =
          0..(slice.max_slices - 1)
          |> Enum.chunk_every(10)
          |> Enum.flat_map(&fetch_slice_ids_chunk(slice, &1))

        Slice.finish(slice)
        {:ok, ids}
    end
  end

  defp fetch_slice_ids_chunk(slice, chunk) do
    chunk
    |> Enum.map(&Task.async(fn -> fetch_slice_ids(slice, &1) end))
    |> Enum.map(&Task.await(&1, 30_000))
    |> List.flatten()
  end

  defp fetch_slice_ids(slice, slice_number) do
    case Slice.slice(slice, slice_number) do
      {:ok, hits} -> Enum.map(hits, fn %{"_id" => id} -> id end)
      {:error, _} -> []
    end
  end

  defp build_members(work_ids) do
    work_ids
    |> Enum.reduce({[], 0}, fn work_id, {acc, skipped} ->
      case build_member_attrs(work_id) do
        nil -> {acc, skipped + 1}
        attrs -> {[attrs | acc], skipped}
      end
    end)
    |> then(fn {members, skipped} -> {Enum.reverse(members), skipped} end)
  end

  defp build_member_attrs(work_id) do
    work = Works.get_work!(work_id)
    dm = work.descriptive_metadata
    subjects = snapshot_subjects(dm.subject || [])
    descriptions = dm.description || []

    if descriptions == [] and length(subjects) < 3 do
      nil
    else
      rep_fs_id = work.representative_file_set_id || first_access_file_set_id(work_id)

      %{
        work_id: work.id,
        accession_number: work.accession_number,
        representative_file_set_id: rep_fs_id,
        ground_truth: %{
          description: descriptions,
          subjects: subjects
        }
      }
    end
  rescue
    _ -> nil
  end

  defp first_access_file_set_id(work_id) do
    case Works.get_access_files(work_id) |> List.first() do
      nil -> nil
      %{id: id} -> id
    end
  end

  defp snapshot_subjects(subject_entries) do
    Enum.map(subject_entries, fn entry ->
      %{
        id: entry.term.id,
        label: entry.term.label
      }
    end)
  end

  # ---------------------------------------------------------------------------
  # Eval Runs
  # ---------------------------------------------------------------------------

  def list_runs(opts \\ []) do
    limit = Keyword.get(opts, :limit, 50)
    offset = Keyword.get(opts, :offset, 0)

    Repo.all(
      from r in EvalRun,
        order_by: [desc: r.inserted_at],
        limit: ^limit,
        offset: ^offset,
        preload: [:eval_set, :prompt_version]
    )
  end

  def get_run!(id) do
    Repo.get!(EvalRun, id)
    |> Repo.preload([:prompt_version, eval_set: :eval_set_members, eval_trials: :scores])
  end

  @doc """
  Create a new run and pre-create all trial rows in :pending state.
  Does NOT start execution — caller is responsible for calling Runner.start/1.
  """
  def create_run(attrs) do
    Repo.transaction(fn ->
      run =
        %EvalRun{}
        |> EvalRun.changeset(attrs)
        |> Repo.insert!()

      set = get_eval_set!(run.eval_set_id)
      trials_per_work = run.trials_per_work

      Enum.each(set.eval_set_members, &insert_trials_for_member(&1, run.id, trials_per_work))

      run
    end)
  end

  defp insert_trials_for_member(member, run_id, trials_per_work) do
    Enum.each(0..(trials_per_work - 1), fn idx ->
      %EvalTrial{}
      |> EvalTrial.changeset(%{
        eval_run_id: run_id,
        work_id: member.work_id,
        trial_index: idx
      })
      |> Repo.insert!()
    end)
  end

  def cancel_run(%EvalRun{} = run) do
    run |> EvalRun.mark_cancelled() |> Repo.update()
  end

  def cancel_run(id) when is_binary(id) do
    get_run!(id) |> cancel_run()
  end

  # ---------------------------------------------------------------------------
  # Eval Trials
  # ---------------------------------------------------------------------------

  def get_trial!(id), do: Repo.get!(EvalTrial, id)

  def list_trials_for_run(run_id) do
    Repo.all(
      from t in EvalTrial,
        where: t.eval_run_id == ^run_id,
        order_by: [asc: t.work_id, asc: t.trial_index],
        preload: :scores
    )
  end

  def record_agent_output(trial_id, output) do
    trial = get_trial!(trial_id)

    trial
    |> Ecto.Changeset.cast(%{agent_output: output}, [:agent_output])
    |> Repo.update()
  end

  @doc """
  Record (or update) the calling user's manual score for a trial.

  Manual scores are per-user: each scorer has at most one `EvalTrialScore` row
  per trial, keyed on `{eval_trial_id, scored_by}`. Re-scoring upserts that row.
  Returns {:ok, eval_trial} with `:scores` preloaded.
  """
  def score_trial(trial_id, score, notes \\ nil, user) when is_binary(trial_id) do
    existing = Repo.get_by(EvalTrialScore, eval_trial_id: trial_id, scored_by: user)

    attrs = %{
      eval_trial_id: trial_id,
      scored_by: user,
      score: score,
      notes: notes,
      scored_at: DateTime.utc_now()
    }

    (existing || %EvalTrialScore{})
    |> EvalTrialScore.changeset(attrs)
    |> Repo.insert_or_update()
    |> case do
      {:ok, _trial_score} -> {:ok, get_trial_with_scores!(trial_id)}
      {:error, changeset} -> {:error, changeset}
    end
  end

  @doc "Remove the calling user's manual score for a trial (no-op if absent)."
  def clear_trial_score(trial_id, user) when is_binary(trial_id) do
    Repo.delete_all(
      from s in EvalTrialScore,
        where: s.eval_trial_id == ^trial_id and s.scored_by == ^user
    )

    {:ok, get_trial_with_scores!(trial_id)}
  end

  defp get_trial_with_scores!(trial_id) do
    EvalTrial |> Repo.get!(trial_id) |> Repo.preload(:scores)
  end

  # ---------------------------------------------------------------------------
  # Run summary stats
  # ---------------------------------------------------------------------------

  @doc """
  Compute summary statistics for a run.

  Manual good/bad counts are scoped to `user_email` — each scorer only sees
  their own tallies. Pass `nil` to count no manual scores.
  Returns a map with trial counts, pass rates, and judge score means.
  """
  def run_summary(run, user_email \\ nil)

  def run_summary(%EvalRun{id: run_id}, user_email) do
    trials = list_trials_for_run(run_id)
    total = length(trials)
    complete = Enum.count(trials, &(&1.status == :complete))
    errored = Enum.count(trials, &(&1.status == :errored))
    pending = Enum.count(trials, &(&1.status == :pending))
    running = Enum.count(trials, &(&1.status == :running))

    manual_good = Enum.count(trials, &(user_score(&1, user_email) == :good))
    manual_bad = Enum.count(trials, &(user_score(&1, user_email) == :bad))

    scored_trials = Enum.filter(trials, &(&1.status == :complete))

    %{
      total: total,
      complete: complete,
      errored: errored,
      pending: pending,
      running: running,
      manual_good: manual_good,
      manual_bad: manual_bad,
      mean_description_judge_score: mean_float(scored_trials, & &1.description_judge_score),
      mean_subjects_judge_score: mean_float(scored_trials, & &1.subjects_judge_score)
    }
  end

  def run_summary(run_id, user_email) when is_binary(run_id),
    do: run_summary(get_run!(run_id), user_email)

  @doc "The given user's manual score (:good/:bad) for a trial, or nil."
  def user_score(_trial, nil), do: nil

  def user_score(%EvalTrial{scores: scores}, user_email) when is_list(scores) do
    case Enum.find(scores, &(&1.scored_by == user_email)) do
      nil -> nil
      score -> score.score
    end
  end

  def user_score(_trial, _user_email), do: nil

  @doc "The given user's full manual score row for a trial, or nil."
  def user_score_record(%EvalTrial{scores: scores}, user_email)
      when is_list(scores) and is_binary(user_email) do
    Enum.find(scores, &(&1.scored_by == user_email))
  end

  def user_score_record(_trial, _user_email), do: nil

  defp mean_float([], _), do: nil

  defp mean_float(trials, getter) do
    values = trials |> Enum.map(getter) |> Enum.reject(&is_nil/1)

    if values == [] do
      nil
    else
      (Enum.sum(values) / length(values)) |> Float.round(3)
    end
  end
end
