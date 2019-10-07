defmodule Meadow.Ingest.IngestSheets.IngestSheetValidator do
  @moduledoc """
  Validates an Ingest Sheet
  """
  alias Meadow.Ingest.IngestSheets
  alias Meadow.Ingest.IngestSheets.{IngestSheet, IngestSheetRow}
  alias Meadow.Repo
  alias NimbleCSV.RFC4180, as: CSV
  import Ecto.Query

  @headers ~w(accession_number description filename role work_accession_number)

  def async(sheet_id) do
    case Meadow.TaskRegistry |> Registry.lookup(sheet_id) do
      [{pid, _}] ->
        {:running, pid}

      _ ->
        Task.start(fn ->
          Meadow.TaskRegistry |> Registry.register(sheet_id, nil)
          result(sheet_id)
        end)
    end
  end

  def result(sheet) do
    validate(sheet)
    |> IngestSheet.find_state()
  end

  def validate(sheet_id) when is_binary(sheet_id) do
    sheet_id
    |> load_sheet()
    |> validate()
  end

  def validate(%IngestSheet{} = sheet) do
    unless Ecto.assoc_loaded?(sheet.project) do
      raise ArgumentError, "Ingest Sheet association not loaded"
    end

    events = [
      {"file", &load_file/1},
      {"rows", &validate_rows/1},
      {"overall", &overall_status/1}
    ]

    with {_, result} <- check_result(sheet, events), do: result
  end

  defp check_result(sheet, {event, func}) do
    case sheet |> IngestSheet.find_state(event) do
      "pass" -> {:ok, sheet}
      "fail" -> {:error, sheet}
      "pending" -> sheet |> func.() |> update_state(event)
    end
  end

  defp check_result(sheet, [process | []]) do
    check_result(sheet, process)
  end

  defp check_result(sheet, [process | rest]) do
    case sheet |> check_result(process) do
      {:ok, result} -> result |> check_result(rest)
      {_, result} -> result |> check_result({"overall", &overall_status/1})
    end
  end

  @max_attempts 5
  defp load_file(sheet, attempt \\ 1) do
    "/" <> filename = URI.parse(sheet.filename).path

    case Application.get_env(:meadow, :upload_bucket)
         |> ExAws.S3.get_object(filename)
         |> ExAws.request() do
      {:error, _} ->
        case attempt do
          @max_attempts ->
            add_file_errors(sheet, ["Could not load ingest sheet from S3"])
            {:error, sheet}

          i ->
            :timer.sleep(1000)
            load_file(sheet, i + 1)
        end

      {:ok, obj} ->
        load_rows(sheet, obj.body)
    end
  end

  defp load_rows(sheet, csv) do
    [headers | rows] = CSV.parse_string(csv, skip_headers: false)
    sorted_headers = Enum.sort(headers)

    case sheet |> validate_headers(sorted_headers) do
      {:ok, sheet} ->
        {:ok, sheet} |> update_state("file")
        insert_rows(sheet, [headers | rows])
        {:ok, sheet}

      {:error, sheet} ->
        {:error, sheet}
    end
  rescue
    e in NimbleCSV.ParseError ->
      add_file_errors(sheet, ["Invalid csv file: " <> e.message])

      {:error, sheet} |> update_state("file")
  end

  defp validate_headers(sheet, headers) do
    case headers do
      @headers ->
        {:ok, sheet}

      _ ->
        missing = check_missing_headers(@headers -- headers)
        invalid = check_invalid_headers(headers -- @headers)
        errors = missing ++ invalid
        add_file_errors(sheet, errors)

        {:error, sheet}
    end
  end

  defp insert_rows(sheet, [headers | rows]) do
    Repo.transaction(fn ->
      rows
      |> Enum.with_index(1)
      |> Enum.map(fn {row, row_num} ->
        now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)

        fields =
          Enum.zip(headers, row)
          |> Enum.reduce([], fn {k, v}, acc ->
            [%IngestSheetRow.Field{header: k, value: v} | acc]
          end)
          |> Enum.reverse()

        %{
          ingest_sheet_id: sheet.id,
          row: row_num,
          fields: fields,
          state: "pending",
          inserted_at: now,
          updated_at: now
        }
      end)
      |> Enum.chunk_every(10_000)
      |> Enum.each(fn chunk ->
        Repo.insert_all(IngestSheetRow, chunk,
          on_conflict: :replace_all_except_primary_key,
          conflict_target: [:ingest_sheet_id, :row]
        )
      end)
    end)
  end

  defp validate_rows(sheet) do
    row_check = fn
      row, result ->
        case validate_row(sheet, row) do
          "pass" -> result
          "fail" -> :error
        end
    end

    overall_row_result = {
      IngestSheets.list_ingest_sheet_rows(sheet: sheet, state: ["pending"])
      |> Enum.reduce(:ok, row_check),
      sheet
    }

    case overall_row_result do
      {:ok, sheet} ->
        IngestSheets.update_ingest_sheet_status(sheet, "valid")
        {:ok, sheet}

      {:error, sheet} ->
        IngestSheets.update_ingest_sheet_status(sheet, "row_fail")
        {:error, sheet}
    end
  end

  defp validate_value({field_name, value}) when byte_size(value) == 0,
    do: {:error, field_name, "#{field_name} cannot be blank"}

  defp validate_value({"filename", value}) do
    response =
      Application.get_env(:meadow, :ingest_bucket)
      |> ExAws.S3.head_object(value)
      |> ExAws.request()

    case response do
      {:ok, %{status_code: 200}} -> :ok
      {:error, {:http_error, 404, _}} -> {:error, "filename", "File not Found: #{value}"}
      {:error, {:http_error, code, _}} -> {:error, "filename", "Status: #{code}"}
    end
  end

  defp validate_value({_field_name, _value}), do: :ok

  defp validate_row(sheet, %IngestSheetRow{state: "pending"} = row) do
    reducer = fn %IngestSheetRow.Field{header: field_name, value: value}, acc ->
      value =
        case {field_name, value} do
          {"filename", v} -> {"filename", sheet.project.folder <> "/" <> v}
          other -> other
        end

      case validate_value(value) do
        :ok -> acc
        {:error, field, error} -> [%{field: field, message: error} | acc]
      end
    end

    result = row.fields |> Enum.reduce([], reducer)

    case result do
      [] ->
        row |> IngestSheets.change_ingest_sheet_row_state("pass")
        "pass"

      errors ->
        row |> IngestSheets.update_ingest_sheet_row(%{state: "fail", errors: errors})
        "fail"
    end
  end

  defp load_sheet(sheet_id) do
    IngestSheet
    |> where([ingest_sheet], ingest_sheet.id == ^sheet_id)
    |> preload(:project)
    |> Repo.one()
  end

  defp overall_status(sheet) do
    state_reducer = fn %{state: state, count: count}, result ->
      case {state, count} do
        {"pending", count} when count > 0 -> {:halt, :pending}
        {"fail", count} when count > 0 -> {:halt, :error}
        _ -> {:cont, result}
      end
    end

    result =
      case "fail" in (sheet.state |> Enum.map(& &1.state)) do
        true ->
          :error

        false ->
          sheet
          |> IngestSheets.list_ingest_sheet_row_counts()
          |> Enum.reduce_while(:ok, state_reducer)
      end

    {result, sheet}
  end

  defp add_file_errors(sheet, messages) do
    sheet
    |> IngestSheets.add_file_errors_to_ingest_sheet(messages)
    |> IngestSheets.update_ingest_sheet_status("file_fail")
  end

  defp update_state({result, sheet}, event) do
    state = %{
      String.to_atom(event) =>
        case result do
          :ok -> "pass"
          :error -> "fail"
          _ -> "pending"
        end
    }

    {result, sheet |> IngestSheets.change_ingest_sheet_state!(state)}
  end

  defp check_missing_headers([_ | _] = missing_headers) do
    [
      "Required " <>
        Inflex.inflect("header", Kernel.length(missing_headers)) <>
        " missing: " <> Enum.join(missing_headers, ",")
    ]
  end

  defp check_missing_headers([]), do: []

  defp check_invalid_headers([_ | _] = invalid_headers) do
    [
      "Invalid " <>
        Inflex.inflect("header", Kernel.length(invalid_headers)) <>
        ": " <> Enum.join(invalid_headers, ",")
    ]
  end

  defp check_invalid_headers([]), do: []
end
