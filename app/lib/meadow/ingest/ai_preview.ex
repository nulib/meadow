defmodule Meadow.Ingest.AIPreview do
  @moduledoc """
  Generates AI metadata previews for AI ingest sheets.

  Finds up to 3 IMAGE works (using the first Access/A role row per work), sends
  all of them to the metadata agent in a single call. The agent uses
  get_ingest_image and authority_search for each work, then returns a JSON array
  of previews. Results are stored in ai_preview on the sheet and the status
  transitions to awaiting_approval.
  """

  require Logger
  alias Meadow.Config
  alias Meadow.Ingest.{Rows, Schemas.Row, Sheets}

  @system_prompt """
  You are a digital library metadata specialist generating structured previews for ingest review.
  Use the available tools to gather information about each work, then respond with ONLY a valid
  JSON array — no preamble, no explanation, no markdown code fences. Your entire response must
  be a single JSON array.
  """

  @prompt_header """
  Generate metadata previews for the following IMAGE works from a library ingest sheet.

  For EACH work listed below:
  1. Call `get_ingest_image` with the S3 URI to view the image.
  2. Call `authority_search` (authority_code: "lcsh") to find 3 appropriate subject headings
     based on what you see — people, places, events, topics, or objects in the image.
  3. Write a concise descriptive summary (1-3 sentences).

  Works to preview:
  """

  @prompt_footer """

  Respond with ONLY a valid JSON array — no preamble, no explanation, no markdown:
  [
    {
      "work_accession_number": "<accession>",
      "subjects": [
        {"id": "<authority URI>", "label": "<label>"},
        {"id": "<authority URI>", "label": "<label>"},
        {"id": "<authority URI>", "label": "<label>"}
      ],
      "description": "<description>"
    }
  ]
  """

  @doc """
  Generate previews for up to 3 IMAGE works in the sheet and store them,
  then transition the sheet to awaiting_approval.
  """
  def generate_and_store(%{id: _} = sheet) do
    Logger.info("AIPreview: generating previews for sheet #{sheet.id}")

    works = find_preview_works(sheet)

    previews =
      case works do
        [] ->
          Logger.info("AIPreview: no IMAGE works with role A found in sheet #{sheet.id}")
          []

        works ->
          case invoke_agent(works) do
            {:ok, results} -> attach_filenames(results, works)
            {:error, reason} -> error_previews(works, reason)
          end
      end

    Logger.info("AIPreview: storing #{length(previews)} preview(s) for sheet #{sheet.id}")
    Sheets.update_ingest_sheet(sheet, %{ai_preview: previews, status: "awaiting_approval"})
  rescue
    error ->
      Logger.error(
        "AIPreview: generation failed for sheet #{sheet.id}: #{Exception.message(error)}"
      )

      Sheets.update_ingest_sheet_status(sheet, "awaiting_approval")
      {:error, error}
  end

  # Find up to 3 IMAGE works that have at least one Access (A) role row,
  # taking the lowest-numbered row per work as the representative image.
  defp find_preview_works(sheet) do
    bucket = Config.ingest_bucket()

    Rows.list_ingest_sheet_rows(sheet_id: sheet.id)
    |> Enum.filter(fn row ->
      Row.field_value(row, "work_type") == "IMAGE" &&
        Row.field_value(row, "role") == "A"
    end)
    |> Enum.group_by(&Row.field_value(&1, "work_accession_number"))
    |> Enum.map(fn {accession, rows} ->
      first_row = Enum.min_by(rows, & &1.row)
      relative_path = Row.field_value(first_row, "filename")
      s3_uri = "s3://#{bucket}/#{relative_path}"
      {accession, s3_uri}
    end)
    |> Enum.take(3)
  end

  defp invoke_agent(works) do
    work_lines =
      works
      |> Enum.with_index(1)
      |> Enum.map(fn {{accession, s3_uri}, idx} ->
        "#{idx}. Work accession: #{accession} | Image: #{s3_uri}"
      end)
      |> Enum.join("\n")

    prompt = @prompt_header <> work_lines <> @prompt_footer

    case MeadowAI.query(prompt, context: %{system_prompt: String.trim(@system_prompt)}) do
      {:ok, response} ->
        Logger.debug("AIPreview: raw agent response: #{inspect(response)}")
        parse_response(response)

      {:error, reason} ->
        Logger.warning("AIPreview: agent call failed: #{inspect(reason)}")
        {:error, reason}
    end
  end

  defp parse_response(text) do
    json_text =
      case Regex.run(~r/\[[\s\S]*\]/U, text) do
        [match] -> match
        _ -> text
      end

    case Jason.decode(json_text) do
      {:ok, results} when is_list(results) ->
        {:ok, results}

      _ ->
        Logger.warning("AIPreview: could not parse JSON array from agent response")
        {:error, :parse_failed}
    end
  end

  # Attach the filename to each parsed result, matching on work_accession_number.
  defp attach_filenames(results, works) do
    filename_map = Map.new(works, fn {accession, s3_uri} -> {accession, s3_uri} end)

    Enum.map(results, fn result ->
      accession = Map.get(result, "work_accession_number", "")
      Map.put(result, "filename", Map.get(filename_map, accession, ""))
    end)
  end

  defp error_previews(works, reason) do
    Enum.map(works, fn {accession, s3_uri} ->
      %{
        "work_accession_number" => accession,
        "filename" => s3_uri,
        "subjects" => [],
        "description" => "",
        "error" => inspect(reason)
      }
    end)
  end
end
