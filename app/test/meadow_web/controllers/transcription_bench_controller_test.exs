defmodule MeadowWeb.TranscriptionBenchControllerTest do
  use Meadow.DataCase
  use MeadowWeb.ConnCase, async: false

  alias Meadow.Repo
  alias Meadow.TranscriptionBench
  alias Meadow.TranscriptionBench.Result
  alias NimbleCSV.RFC4180, as: CSV

  setup do
    file_set =
      file_set_fixture_attrs(%{
        role: %{id: "A", scheme: "FILE_SET_ROLE"},
        core_metadata: %{
          location: "s3://bucket/letter.tif",
          original_filename: "letter.tif",
          label: "Letter, page 1",
          mime_type: "image/tiff"
        },
        derivatives: %{"pyramid_tiff" => "s3://pyramids/letter.tif"}
      })

    [file_set] = work_fixture(%{file_sets: [file_set]}).file_sets

    {:ok, run} =
      TranscriptionBench.create_run(%{
        name: "Lines, \"quoted\"",
        author: "editor@example.edu",
        file_set_ids: [file_set.id],
        models: ["us.anthropic.claude-sonnet-4-6"],
        variants: [
          %{"id" => "lines", "name" => "Lines", "prompt" => "Transcribe.", "boxUnits" => "px"}
        ]
      })

    Repo.update_all(Result,
      set: [
        status: "done",
        duration_ms: 12_340,
        sent_width: 1000,
        sent_height: 2000,
        image_width: 3000,
        image_height: 6000,
        usage: %{"inputTokens" => 1200, "outputTokens" => 30},
        tool_input:
          ~s({"lines": [{"text": "Dear Sir,", "box": [100, 200, 500, 300]}, {"text": "no box"}],) <>
            ~s( "detected_languages": ["en"]})
      ]
    )

    {:ok, run: run, file_set: file_set}
  end

  defp rows(conn) do
    assert "﻿" <> csv = response(conn, 200)
    CSV.parse_string(csv, skip_headers: false)
  end

  test "refuses a request that is not signed in", %{conn: conn, run: run} do
    conn = post(conn, "/api/transcription_bench/run.csv", %{run_id: run.id})
    assert text_response(conn, 403) =~ "Unauthorized"
  end

  test "an unknown run, and no run", %{conn: conn} do
    conn = auth_user(conn, user_fixture(:editor))

    assert conn
           |> post("/api/transcription_bench/run.csv", %{run_id: Ecto.UUID.generate()})
           |> text_response(404) =~ "not found"

    assert conn |> post("/api/transcription_bench/run.csv", %{}) |> text_response(400) =~
             "Missing run_id"
  end

  test "one row per result", %{conn: conn, run: run, file_set: file_set} do
    conn =
      conn
      |> auth_user(user_fixture(:editor))
      |> post("/api/transcription_bench/run.csv", %{run_id: run.id})

    assert get_resp_header(conn, "content-disposition") == [~s(attachment; filename="run.csv")]
    assert [headers, row] = rows(conn)
    result = headers |> Enum.zip(row) |> Map.new()

    assert %{
             "run_name" => "Lines, \"quoted\"",
             "author" => "editor@example.edu",
             "image" => "Letter, page 1",
             "model" => "us.anthropic.claude-sonnet-4-6",
             "variant" => "Lines",
             "status" => "done",
             "duration_s" => "12.3",
             "input_tokens" => "1200",
             "output_tokens" => "30",
             "levels" => "lines",
             "regions" => "2",
             "regions_with_box" => "1",
             "languages" => "en",
             "text" => "Dear Sir,\nno box",
             "error" => ""
           } = result

    assert result["file_set_id"] == file_set.id
  end

  test "one row per region", %{conn: conn, run: run} do
    conn =
      conn
      |> auth_user(user_fixture(:editor))
      |> post("/api/transcription_bench/regions.csv", %{run_id: run.id, kind: "regions"})

    assert [headers, boxed, unboxed] = rows(conn)
    boxed = headers |> Enum.zip(boxed) |> Map.new()

    assert %{
             "level" => "lines",
             "index" => "0",
             "text" => "Dear Sir,",
             "x_fraction" => "0.1",
             "y_fraction" => "0.1",
             "width_fraction" => "0.4",
             "height_fraction" => "0.05",
             "x_px" => "300",
             "y_px" => "600",
             "width_px" => "1200",
             "height_px" => "300",
             "model_box" => "[100,200,500,300]"
           } = boxed

    assert %{"text" => "no box", "x_px" => "", "model_box" => ""} =
             headers |> Enum.zip(unboxed) |> Map.new()
  end
end
