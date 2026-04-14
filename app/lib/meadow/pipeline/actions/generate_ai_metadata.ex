defmodule Meadow.Pipeline.Actions.GenerateAIMetadata do
  @moduledoc "Generate AI metadata (subjects and description) for image works in AI ingest"

  alias Meadow.Data.{ActionStates, Works}
  alias Meadow.Data.Schemas.Work
  alias Meadow.Ingest.Sheets
  use Meadow.Pipeline.Actions.Common
  require Logger

  @system_prompt """
  You are a digital library metadata specialist generating structured metadata for image works.
  Use the available tools to analyze the image, find appropriate subject headings, then call
  apply_work_metadata to store the results. Do not return the results as text.
  """

  def actiondoc, do: "Generate AI metadata for image works"

  # When overwrite: "false" (e.g. version re-ingest), always treat as already complete.
  def already_complete?(_file_set, _attributes), do: true

  def process(file_set, attributes) do
    with %{context: "Sheet"} <- attributes,
         work when not is_nil(work) <- load_work(file_set),
         true <- ai_ingest_work?(work),
         true <- work_image?(file_set, work) do
      run_generation(file_set, work)
    else
      _ ->
        ActionStates.set_state!(file_set, __MODULE__, "ok")
        :ok
    end
  end

  defp run_generation(file_set, work) do
    prompt = """
    Analyze the following IMAGE work from a digital library collection.

    Work ID: #{work.id}
    File Set ID: #{file_set.id}
    Accession Number: #{work.accession_number}

    1. Call `get_image` with file_set_id: "#{file_set.id}" to view the image.
    2. Call `authority_search`  to find 3 appropriate subject headings
      based on what you see — people, places, events, topics, or objects in the image.
      Use authority_code: "lcnaf" for names and "fast" for everything else.
    3. Write a concise descriptive summary (1-3 sentences).
    4. Call `apply_work_metadata` with:
       - work_id: "#{work.id}"
       - description: your 1-3 sentence summary
       - subjects: array from authority_search results, each with id and label
    """

    case MeadowAI.query(prompt, context: %{system_prompt: String.trim(@system_prompt)}) do
      {:ok, response} ->
        cost = Map.get(response, "total_cost_usd", 0.0) |> Float.round(2)
        Sheets.cost_delta(work.ingest_sheet_id, cost)
        ActionStates.set_state!(file_set, __MODULE__, "ok")
        :ok

      {:error, reason} ->
        Logger.error("GenerateAIMetadata: agent failed for #{file_set.id}: #{inspect(reason)}")
        ActionStates.set_state!(file_set, __MODULE__, "error", inspect(reason))
        {:error, reason}
    end
  end

  defp load_work(%{work_id: nil}), do: nil
  defp load_work(%{work_id: work_id}), do: Works.get_work!(work_id)

  # Works.get_work! preloads :ingest_sheet, giving access to ai_ingest
  defp ai_ingest_work?(%Work{ingest_sheet: %{ai_ingest: true}}), do: true
  defp ai_ingest_work?(_), do: false

  # If work_image: TRUE was set in the sheet, representative_file_set_id was set before kickoff
  defp work_image?(file_set, %Work{representative_file_set_id: nil, id: work_id}) do
    # Fallback: first access file set by rank
    case Works.get_access_files(work_id) |> List.first() do
      nil -> false
      %{id: id} -> file_set.id == id
    end
  end

  defp work_image?(file_set, %Work{representative_file_set_id: rep_id}),
    do: file_set.id == rep_id
end
