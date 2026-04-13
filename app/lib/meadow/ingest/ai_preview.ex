defmodule Meadow.Ingest.AIPreview do
  @moduledoc """
  Generates AI metadata previews for AI ingest sheets.

  Finds up to 3 IMAGE works (using the first Access/A role row per work) and
  sends them to the metadata agent. The agent calls get_ingest_image and
  authority_search for each work, then submits the structured results via the
  submit_ai_previews MCP tool, which writes them directly to the sheet.
  The sheet status is then transitioned to awaiting_approval.
  """

  require Logger
  alias Meadow.Config
  alias Meadow.Ingest.{Rows, Schemas.Row, Sheets}

  @system_prompt """
  You are a digital library metadata specialist generating structured previews for ingest review.
  Use the available tools to gather information about each work, then call submit_ai_previews
  to store the results. Do not return the results as text.
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

  @doc """
  Generate previews for up to 3 IMAGE works in the sheet and store them,
  then transition the sheet to awaiting_approval.
  """
  def generate_and_store(%{id: _} = sheet) do
    Logger.info("AIPreview: generating previews for sheet #{sheet.id}")

    works = find_preview_works(sheet)

    case works do
      [] ->
        Logger.info("AIPreview: no IMAGE works with role A found in sheet #{sheet.id}")

      works ->
        case invoke_agent(works, sheet.id) do
          {:ok, _} -> :ok
          {:error, reason} -> Logger.warning("AIPreview: agent call failed: #{inspect(reason)}")
        end
    end

    Sheets.update_ingest_sheet_status(sheet, "awaiting_approval")
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

  defp invoke_agent(works, sheet_id) do
    work_lines =
      works
      |> Enum.with_index(1)
      |> Enum.map_join("\n", fn {{accession, s3_uri}, idx} ->
        "#{idx}. Work accession: #{accession} | Image: #{s3_uri}"
      end)

    prompt =
      @prompt_header <>
        work_lines <>
        """


        When you have finished analyzing all works, call `submit_ai_previews` with:
          - sheet_id: "#{sheet_id}"
          - previews: an array with one entry per work, each containing:
              - work_accession_number
              - filename (the S3 URI from the work listing above)
              - description
              - subjects (array of {id, label} from authority_search)
        """

    case MeadowAI.query(prompt, context: %{system_prompt: String.trim(@system_prompt)}) do
      {:ok, response} ->
        Logger.debug("AIPreview: agent response: #{inspect(response)}")
        {:ok, response}

      {:error, reason} ->
        Logger.warning("AIPreview: agent call failed: #{inspect(reason)}")
        {:error, reason}
    end
  end
end
