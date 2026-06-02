defmodule MeadowWeb.EvalsController do
  use MeadowWeb, :controller
  alias Meadow.Evals
  alias Meadow.Roles
  alias NimbleCSV.RFC4180, as: CSV
  import Plug.Conn

  plug(:authorize_user)

  @csv_headers ~w(
    run_id prompt_version eval_set
    work_id accession_number status
    gt_description gt_subjects
    agent_description agent_subjects
    description_judge_score subjects_judge_score judge_rationale
    manual_score manual_scored_by
    duration_ms error
  )

  def export(conn, %{"file" => file, "run_id" => run_id}) do
    run = Evals.get_run!(run_id)
    set = run.eval_set
    prompt = run.prompt_version

    set_members = Map.new(set.eval_set_members, &{&1.work_id, &1})

    conn =
      conn
      |> put_resp_content_type("text/csv")
      |> put_resp_header("content-disposition", ~s[attachment; filename="#{file}"])
      |> send_chunked(:ok)

    header_row = CSV.dump_to_iodata([@csv_headers])
    chunk(conn, header_row)

    for trial <- run.eval_trials do
      member = Map.get(set_members, trial.work_id)
      row = trial_row(run, set, prompt, trial, member)
      chunk(conn, CSV.dump_to_iodata([row]))
    end

    conn
  rescue
    Ecto.NoResultsError ->
      conn
      |> put_resp_content_type("text/plain")
      |> resp(404, "Eval run not found")
      |> halt()
  end

  def export(conn, _params) do
    conn
    |> put_resp_content_type("text/plain")
    |> resp(400, "Missing run_id parameter")
    |> halt()
  end

  defp trial_row(run, set, prompt, trial, member) do
    gt = blank_map(member && member.ground_truth)
    gt_desc = gt |> Map.get(:description, Map.get(gt, "description", [])) |> List.wrap() |> Enum.join(" | ")
    gt_subjects = gt |> Map.get(:subjects, Map.get(gt, "subjects", [])) |> join_subject_ids()

    agent_out = blank_map(trial.agent_output)
    agent_desc = Map.get(agent_out, :description, Map.get(agent_out, "description", ""))
    agent_subjects = agent_out |> Map.get(:subjects, Map.get(agent_out, "subjects", [])) |> join_subject_ids()

    [
      run.id,
      blank(prompt && prompt.name),
      blank(set && set.name),
      trial.work_id,
      blank(member && member.accession_number),
      trial.status,
      gt_desc,
      gt_subjects,
      agent_desc,
      agent_subjects,
      blank(trial.description_judge_score),
      blank(trial.subjects_judge_score),
      blank(trial.judge_rationale),
      trial.manual_score,
      blank(trial.manual_scored_by),
      blank(trial.duration_ms),
      blank(trial.error)
    ]
    |> Enum.map(&to_string/1)
  end

  defp blank(nil), do: ""
  defp blank(value), do: value

  defp blank_map(map) when is_map(map), do: map
  defp blank_map(_), do: %{}

  defp join_subject_ids(subjects) do
    Enum.map_join(subjects, ", ", fn s ->
      id = Map.get(s, :id) || Map.get(s, "id") || ""
      label = Map.get(s, :label) || Map.get(s, "label")
      if label && label != "", do: "#{id} (#{label})", else: id
    end)
  end

  def authorize_user(%{assigns: %{current_user: current_user}} = conn, _params) do
    if Roles.authorized?(current_user, :editor) do
      conn
    else
      conn
      |> put_resp_content_type("text/plain")
      |> resp(403, "Unauthorized")
      |> halt()
    end
  end
end
