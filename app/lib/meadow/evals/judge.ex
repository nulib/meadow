defmodule Meadow.Evals.Judge do
  @moduledoc "LLM-as-judge semantic scoring for eval trials via AWS Bedrock Converse."

  alias Meadow.Config
  require Logger

  @default_model "us.anthropic.claude-sonnet-4-6"
  @max_tokens 512

  @judge_system_prompt """
  You are a metadata quality evaluator for a digital library. Compare AI-generated metadata
  against a cataloger's ground-truth metadata for the same cultural heritage object. The
  cataloger's data is known to be incomplete — the AI may provide additional accurate details
  beyond what the cataloger noted. Judge based on factual consistency and topic coverage, not
  vocabulary match or length.
  """

  @doc """
  Score an eval trial's agent output against ground truth using an LLM judge.

  Returns {:ok, %{description_judge_score, subjects_judge_score, judge_rationale}}
  or {:error, reason}. On error the caller should store nil for judge fields.
  """
  @spec score(map(), map()) ::
          {:ok, %{description_judge_score: float() | nil, subjects_judge_score: float() | nil, judge_rationale: String.t() | nil}}
          | {:error, term()}
  def score(agent_output, ground_truth) do
    gt_desc = extract_description(ground_truth)
    gt_subjects = extract_subjects(ground_truth)
    agent_desc = extract_description(agent_output)
    agent_subjects = extract_subjects(agent_output)

    prompt = build_prompt(gt_desc, gt_subjects, agent_desc, agent_subjects)

    with {:ok, model_id} <- judge_model(),
         {:ok, text} <- invoke_bedrock(model_id, prompt) do
      parse_response(text)
    end
  rescue
    error ->
      Logger.error("Evals.Judge.score failed: #{Exception.message(error)}")
      {:error, {:judge_exception, Exception.message(error)}}
  end

  # ---------------------------------------------------------------------------
  # Private
  # ---------------------------------------------------------------------------

  defp judge_model do
    case Config.ai(:transcriber_model, @default_model) do
      model when is_binary(model) and byte_size(model) > 0 -> {:ok, model}
      _ -> {:ok, @default_model}
    end
  end

  defp invoke_bedrock(model_id, prompt) do
    body = %{
      "system" => [%{"text" => @judge_system_prompt |> String.trim()}],
      "messages" => [%{"role" => "user", "content" => [%{"text" => prompt}]}],
      "inferenceConfig" => %{"maxTokens" => @max_tokens, "temperature" => 0}
    }

    operation = %ExAws.Operation.JSON{
      data: body,
      headers: [{"Content-Type", "application/json"}],
      http_method: :post,
      path: "/model/#{model_id}/converse",
      service: :"bedrock-runtime"
    }

    case ExAws.request(operation, service_override: :bedrock) do
      {:ok, %{"output" => %{"message" => %{"content" => [%{"text" => text} | _]}}}} ->
        {:ok, text}

      {:ok, unexpected} ->
        Logger.warning("Evals.Judge: unexpected Bedrock response: #{inspect(unexpected)}")
        {:error, {:unexpected_response, unexpected}}

      {:error, reason} ->
        Logger.error("Evals.Judge: Bedrock call failed: #{inspect(reason)}")
        {:error, reason}
    end
  end

  defp parse_response(text) do
    # Strip markdown code fences and whitespace, then extract JSON object
    cleaned =
      text
      |> String.replace(~r/```(?:json)?\s*/i, "")
      |> String.replace("```", "")
      |> String.trim()

    decoded =
      case Jason.decode(cleaned) do
        {:ok, map} ->
          {:ok, map}

        _ ->
          case Regex.run(~r/\{.+\}/s, cleaned) do
            [json] -> Jason.decode(json)
            nil -> {:error, :no_json_found}
          end
      end

    case decoded do
      {:ok, map} ->
        desc_score = parse_score(Map.get(map, "description_score"))
        subj_score = parse_score(Map.get(map, "subjects_score"))
        rationale = Map.get(map, "rationale", "") |> to_string() |> String.slice(0, 500)

        {:ok,
         %{
           description_judge_score: desc_score,
           subjects_judge_score: subj_score,
           judge_rationale: if(rationale == "", do: nil, else: rationale)
         }}

      {:error, reason} ->
        Logger.warning("Evals.Judge: could not parse judge JSON: #{inspect(reason)}\nRaw: #{text}")
        {:error, {:json_parse_failed, reason}}
    end
  end

  defp parse_score(nil), do: nil

  defp parse_score(value) when is_number(value) do
    Float.round(max(0.0, min(1.0, value / 1)), 3)
  end

  defp parse_score(value) when is_binary(value) do
    case Float.parse(value) do
      {f, _} -> parse_score(f)
      :error -> nil
    end
  end

  defp parse_score(_), do: nil

  defp extract_description(map) when is_map(map) do
    (Map.get(map, "description") || Map.get(map, :description) || "")
    |> List.wrap()
    |> Enum.join(" ")
    |> String.trim()
  end

  defp extract_description(_), do: ""

  defp extract_subjects(map) when is_map(map) do
    (Map.get(map, "subjects") || Map.get(map, :subjects) || [])
    |> Enum.map(fn s ->
      label = Map.get(s, "label") || Map.get(s, :label) || ""
      id = Map.get(s, "id") || Map.get(s, :id) || ""
      if label != "", do: label, else: id
    end)
    |> Enum.reject(&(&1 == ""))
    |> Enum.join("; ")
  end

  defp extract_subjects(_), do: ""

  defp build_prompt(gt_desc, gt_subjects, agent_desc, agent_subjects) do
    """
    Score the AI-generated metadata against the cataloger's metadata.

    SCORING DIMENSIONS (each 0.0–1.0):

    description_score — Fidelity of the AI description to the cataloger's stated facts:
    • 1.0: AI covers all cataloger facts; any extras are plausible and consistent
    • 0.7–0.9: Covers most key facts; minor omissions or stylistic differences
    • 0.4–0.6: Partial overlap; substantive gaps or mild contradictions
    • 0.0–0.3: Mostly misses cataloger facts or directly contradicts them
    DO NOT penalize the AI for providing more detail than the cataloger.

    subjects_score — Alignment of AI subjects with cataloger subjects:
    • Treat LCSH and FAST subjects with the same meaning as equivalent
    • Reward coverage of the cataloger's main topics regardless of vocabulary
    • DO NOT penalize extra plausible subjects
    • Penalize only: (a) missing major cataloger topics, (b) clearly off-topic additions
    • 1.0: All major cataloger topics represented; extras are plausible
    • 0.7–0.9: Most cataloger topics covered; minor gaps
    • 0.4–0.6: Several cataloger topics missing or some questionable additions
    • 0.0–0.3: Most cataloger topics absent or AI subjects are largely off-topic

    Return ONLY valid JSON with no other text:
    {"description_score": <float>, "subjects_score": <float>, "rationale": "<1-2 sentences>"}

    ---

    CATALOGER DESCRIPTION:
    #{if gt_desc == "", do: "(none provided)", else: gt_desc}

    CATALOGER SUBJECTS:
    #{if gt_subjects == "", do: "(none provided)", else: gt_subjects}

    AI DESCRIPTION:
    #{if agent_desc == "", do: "(none provided)", else: agent_desc}

    AI SUBJECTS:
    #{if agent_subjects == "", do: "(none provided)", else: agent_subjects}
    """
    |> String.trim()
  end
end
