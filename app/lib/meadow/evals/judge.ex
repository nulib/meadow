defmodule Meadow.Evals.Judge do
  @moduledoc "LLM-as-judge semantic scoring for eval trials via AWS Bedrock Converse."

  alias Meadow.Config
  alias Meadow.HTTP
  alias Meadow.Utils.DCAPI
  require Logger

  @default_model "us.anthropic.claude-sonnet-4-6"
  @max_tokens 512

  # Eval-safe IIIF derivative (matches MeadowWeb.MCP.Tools.GetImage), capped at 1024px.
  @image_path "full/%5E!1024,1024/0/default.jpg"
  @image_token_ttl 600_000

  @judge_system_prompt """
  You are a metadata quality evaluator for a digital library. Compare AI-generated metadata
  against a cataloger's ground-truth metadata for the same cultural heritage object. An image
  of the object itself is normally provided alongside the metadata — use it as the primary
  source of truth for verifying the AI's factual claims.

  How to use the image:
  • Judge whether the AI description and subjects actually match the object in the image.
  • The cataloger's data is known to be incomplete; reward accurate AI detail that the image
    confirms, even when the cataloger did not note it.
  • If the cataloger's text is clearly placeholder or test data that does NOT describe the
    pictured object (e.g. "Photograph number 2 from the test collection", "test description",
    a bare accession/identifier), treat that dimension as if the cataloger provided nothing —
    do not penalize the AI for disagreeing with non-descriptive placeholder text.

  CRITICAL — missing cataloger data: A dimension whose cataloger value is "(none provided)",
  or which is placeholder/test data per the rule above, has NO usable ground truth. Return
  null for that dimension's score (it is not applicable) rather than guessing. Never award a
  high OR a low score simply because the cataloger field is empty or non-descriptive — the
  absence of cataloger data is neither good nor bad. Apply this rule independently to
  description and subjects.
  """

  @doc """
  Score an eval trial's agent output against ground truth using an LLM judge.

  When `opts[:file_set_id]` is given, the object's IIIF image is fetched and sent
  to the judge so it can verify the AI's claims against the actual object (and
  recognize placeholder/test ground truth). Image fetching is best-effort: on
  failure the judge falls back to a text-only comparison.

  Returns {:ok, %{description_judge_score, subjects_judge_score, judge_rationale}}
  or {:error, reason}. On error the caller should store nil for judge fields.
  """
  @spec score(map(), map(), keyword()) ::
          {:ok,
           %{
             description_judge_score: float() | nil,
             subjects_judge_score: float() | nil,
             judge_rationale: String.t() | nil
           }}
          | {:error, term()}
  def score(agent_output, ground_truth, opts \\ []) do
    gt_desc = extract_description(ground_truth)
    gt_subjects = extract_subjects(ground_truth)
    agent_desc = extract_description(agent_output)
    agent_subjects = extract_subjects(agent_output)

    image = fetch_image(Keyword.get(opts, :file_set_id))
    prompt = build_prompt(gt_desc, gt_subjects, agent_desc, agent_subjects, image_present?(image))

    with {:ok, model_id} <- judge_model(),
         {:ok, text} <- invoke_bedrock(model_id, prompt, image) do
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

  defp invoke_bedrock(model_id, prompt, image) do
    body = %{
      "system" => [%{"text" => @judge_system_prompt |> String.trim()}],
      "messages" => [%{"role" => "user", "content" => message_content(prompt, image)}],
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

  # Image block first, then text — mirrors Meadow.Data.Transcriber's Converse layout.
  defp message_content(prompt, {:ok, base64}) do
    [
      %{"image" => %{"format" => "jpeg", "source" => %{"bytes" => base64}}},
      %{"text" => prompt}
    ]
  end

  defp message_content(prompt, _no_image), do: [%{"text" => prompt}]

  defp image_present?({:ok, _base64}), do: true
  defp image_present?(_), do: false

  # Best-effort fetch of the eval-safe IIIF derivative as base64. Any failure
  # (missing id, no token, HTTP error) degrades to a text-only judge call.
  defp fetch_image(nil), do: {:error, :no_file_set}

  defp fetch_image(file_set_id) when is_binary(file_set_id) do
    uri =
      Config.iiif_server_url()
      |> Path.join(file_set_id)
      |> Path.join(@image_path)

    with {:ok, %{token: token}} <-
           DCAPI.token(@image_token_ttl,
             scopes: ["read:Public", "read:Published", "read:Private", "read:Unpublished"],
             is_superuser: true
           ),
         {:ok, %{status: 200, body: body}} <-
           HTTP.get(uri, headers: [{"Authorization", "Bearer #{token}"}]) do
      {:ok, Base.encode64(body)}
    else
      other ->
        Logger.warning("Evals.Judge: could not fetch image for #{file_set_id}: #{inspect(other)}")
        {:error, {:image_fetch_failed, other}}
    end
  end

  defp fetch_image(_), do: {:error, :invalid_file_set}

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
        Logger.warning(
          "Evals.Judge: could not parse judge JSON: #{inspect(reason)}\nRaw: #{text}"
        )

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

  defp build_prompt(gt_desc, gt_subjects, agent_desc, agent_subjects, image_present?) do
    """
    Score the AI-generated metadata against the cataloger's metadata.
    #{image_note(image_present?)}
    SCORING DIMENSIONS (each 0.0–1.0, or null when the cataloger value is "(none provided)"
    or is placeholder/test data that does not describe the pictured object):

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

    If a cataloger value is "(none provided)", or is placeholder/test data that does not
    describe the object shown in the image, return null for that dimension's score.

    Return ONLY valid JSON with no other text:
    {"description_score": <float or null>, "subjects_score": <float or null>, "rationale": "<1-2 sentences>"}

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

  defp image_note(true) do
    "\nAn image of the object is attached to this message. Use it as the primary source of " <>
      "truth for verifying the AI's claims and for spotting placeholder/test cataloger data.\n"
  end

  defp image_note(false), do: ""
end
