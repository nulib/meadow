defmodule MeadowWeb.TranscriptionBenchController do
  @moduledoc """
  A transcription bench run as CSV: one row per result (`kind=results`, the default) or
  one row per region (`kind=regions`).
  """
  use MeadowWeb, :controller
  alias Meadow.Roles
  alias Meadow.TranscriptionBench
  alias NimbleCSV.RFC4180, as: CSV
  import Plug.Conn

  plug(:authorize_user)

  @result_headers ~w(
    run_id run_name run_started_at author
    file_set_id image model variant status error
    duration_s input_tokens output_tokens stop_reason
    image_width image_height sent_width sent_height processed_width processed_height
    levels regions regions_with_box characters languages text
  )

  @region_headers ~w(
    run_id file_set_id image model variant
    level index parent_index text
    x_fraction y_fraction width_fraction height_fraction
    x_px y_px width_px height_px model_box
  )

  def export(conn, %{"file" => file, "run_id" => run_id} = params) do
    case TranscriptionBench.get_run(run_id) do
      nil ->
        conn
        |> put_resp_content_type("text/plain")
        |> resp(404, "Transcription run not found")
        |> halt()

      run ->
        {headers, rows} =
          case params["kind"] do
            "regions" -> {@region_headers, Stream.flat_map(run.results, &region_rows(run, &1))}
            _ -> {@result_headers, Stream.map(run.results, &result_row(run, &1))}
          end

        conn =
          conn
          |> put_resp_content_type("text/csv")
          |> put_resp_header("content-disposition", ~s[attachment; filename="#{file}"])
          |> send_chunked(:ok)

        # The byte order mark has Excel read the file as UTF-8.
        {:ok, conn} = chunk(conn, [<<0xEF, 0xBB, 0xBF>>, CSV.dump_to_iodata([headers])])

        Enum.reduce(rows, conn, fn row, conn ->
          {:ok, conn} = chunk(conn, CSV.dump_to_iodata([Enum.map(row, &cell/1)]))
          conn
        end)
    end
  end

  def export(conn, _params) do
    conn
    |> put_resp_content_type("text/plain")
    |> resp(400, "Missing run_id parameter")
    |> halt()
  end

  defp result_row(run, result) do
    usage = result.usage || %{}

    [
      run.id,
      run.name,
      run.inserted_at,
      run.author,
      result.file_set_id,
      result.label,
      result.model,
      variant_name(run, result.variant_id),
      result.status,
      result.error,
      seconds(result.duration_ms),
      usage["inputTokens"],
      usage["outputTokens"],
      result.stop_reason,
      result.image_width,
      result.image_height,
      result.sent_width,
      result.sent_height,
      result.processed_width,
      result.processed_height
    ] ++ parsed_cells(result.parsed)
  end

  defp parsed_cells(%{"regions" => regions, "text" => text} = parsed) do
    [
      Enum.join(parsed["levels"], " > "),
      length(regions),
      Enum.count(regions, & &1["box"]),
      String.length(text),
      Enum.join(parsed["languages"], " "),
      text
    ]
  end

  defp parsed_cells(_), do: List.duplicate(nil, 6)

  defp seconds(nil), do: nil
  defp seconds(milliseconds), do: Float.round(milliseconds / 1000, 1)

  defp region_rows(run, %{parsed: %{"regions" => regions}} = result) do
    variant = variant_name(run, result.variant_id)

    Enum.map(regions, fn region ->
      [x, y, width, height] = region["box"] || [nil, nil, nil, nil]

      [
        run.id,
        result.file_set_id,
        result.label,
        result.model,
        variant,
        region["level"],
        region["index"],
        region["parent"],
        region["text"],
        x,
        y,
        width,
        height,
        pixels(x, result.image_width),
        pixels(y, result.image_height),
        pixels(width, result.image_width),
        pixels(height, result.image_height),
        region["rawBox"] && Jason.encode!(region["rawBox"])
      ]
    end)
  end

  defp region_rows(_run, _result), do: []

  defp pixels(fraction, extent) when is_number(fraction) and is_integer(extent),
    do: round(fraction * extent)

  defp pixels(_fraction, _extent), do: nil

  defp variant_name(run, id) do
    case Enum.find(run.variants, &(&1["id"] == id)) do
      %{"name" => name} -> name
      _ -> id
    end
  end

  defp cell(nil), do: ""
  defp cell(false), do: ""
  defp cell(value), do: to_string(value)

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
