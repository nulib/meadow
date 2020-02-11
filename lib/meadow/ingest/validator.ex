defmodule Meadow.Ingest.Validator do
  @moduledoc """
  Validates an Ingest Sheet
  """

  alias Meadow.Config
  alias Meadow.Data.{FileSets, Works}
  alias Meadow.Ingest.{Rows, Sheets}
  alias Meadow.Ingest.Schemas.{Row, Sheet}
  alias Meadow.Repo
  alias Meadow.Utils.MapList
  alias NimbleCSV.RFC4180, as: CSV
  import Ecto.Query

  use Meadow.Constants

  def result(sheet) do
    validate(sheet)
    |> Sheet.find_state()
  end

  def validate(sheet_id) when is_binary(sheet_id) do
    sheet_id
    |> load_sheet()
    |> validate()
  end

  def validate(%Sheet{} = sheet) do
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
    case sheet |> Sheet.find_state(event) do
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
  @sleep_time if Mix.env() == :test, do: 10, else: 1000
  def load_file(sheet, attempt \\ 1) do
    "/" <> filename = URI.parse(sheet.filename).path

    case Config.upload_bucket()
         |> ExAws.S3.get_object(filename)
         |> ExAws.request() do
      {:error, _} ->
        case attempt do
          @max_attempts ->
            add_file_errors(sheet, ["Could not load ingest sheet from S3"])
            {:error, sheet}

          i ->
            :timer.sleep(@sleep_time)
            load_file(sheet, i + 1)
        end

      {:ok, obj} ->
        load_rows(sheet, obj.body)
    end
  end

  def load_rows(sheet, csv) do
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
      @ingest_sheet_headers ->
        {:ok, sheet}

      _ ->
        missing = check_missing_headers(@ingest_sheet_headers -- headers)
        invalid = check_invalid_headers(headers -- @ingest_sheet_headers)
        errors = missing ++ invalid
        add_file_errors(sheet, errors)

        {:error, sheet}
    end
  end

  defp transform_fields(sheet, headers, row) do
    Enum.zip(headers, row)
    |> Enum.reduce([], fn {k, v}, acc ->
      v =
        case k do
          "filename" -> sheet.project.folder <> "/" <> v
          _ -> v
        end

      [%Row.Field{header: k, value: v} | acc]
    end)
    |> Enum.reverse()
  end

  defp insert_rows(sheet, [headers | rows]) do
    Repo.transaction(fn ->
      rows
      |> Enum.with_index(1)
      |> Enum.map(fn {row, row_num} ->
        now = DateTime.utc_now()
        fields = transform_fields(sheet, headers, row)

        file_set_accession_number = MapList.get(fields, :header, :value, :accession_number)

        %{
          id: Ecto.UUID.generate(),
          sheet_id: sheet.id,
          row: row_num,
          file_set_accession_number: file_set_accession_number,
          fields: fields,
          state: "pending",
          inserted_at: now,
          updated_at: now
        }
      end)
      |> Enum.chunk_every(10_000)
      |> Enum.each(fn chunk ->
        Repo.insert_all(Row, chunk,
          on_conflict: {:replace_all_except, [:id]},
          conflict_target: [:sheet_id, :row]
        )
      end)
    end)
  end

  defp validate_rows(sheet) do
    row_check = fn
      row, result ->
        case validate_row(row) do
          "pass" -> result
          "fail" -> :error
        end
    end

    overall_row_result = {
      Rows.list_ingest_sheet_rows(sheet: sheet, state: ["pending"])
      |> Enum.reduce(:ok, row_check),
      sheet
    }

    case overall_row_result do
      {:ok, sheet} ->
        Sheets.update_ingest_sheet_status(sheet, "valid")
        {:ok, sheet}

      {:error, sheet} ->
        Sheets.update_ingest_sheet_status(sheet, "row_fail")
        {:error, sheet}
    end
  end

  defp validate_value({field_name, value}) when byte_size(value) == 0,
    do: {:error, field_name, "#{field_name} cannot be blank"}

  defp validate_value({"role", value}) do
    case Enum.member?(@file_set_roles, value) do
      true ->
        :ok

      false ->
        {:error, "role", "role: #{value} is invalid"}
    end
  end

  defp validate_value({"accession_number", value}) do
    case FileSets.accession_exists?(value) do
      true ->
        {:error, "accession_number", "accession_number #{value} already exists in system"}

      false ->
        :ok
    end
  end

  defp validate_value({"work_accession_number", value}) do
    case Works.accession_exists?(value) do
      true ->
        {:error, "work_accession_number",
         "work_accession_number #{value} already exists in system"}

      false ->
        :ok
    end
  end

  defp validate_value({"filename", value}) do
    response =
      Config.ingest_bucket()
      |> ExAws.S3.head_object(value)
      |> ExAws.request()

    case response do
      {:ok, %{status_code: 200}} -> :ok
      {:error, {:http_error, 404, _}} -> {:error, "filename", "File not Found: #{value}"}
      {:error, {:http_error, code, _}} -> {:error, "filename", "Status: #{code}"}
    end
  end

  defp validate_value({_field_name, _value}), do: :ok

  defp validate_row(%Row{state: "pending"} = row) do
    reducer = fn %Row.Field{header: field_name, value: value}, acc ->
      case validate_value({field_name, value}) do
        :ok -> acc
        {:error, field, error} -> [%{field: field, message: error} | acc]
      end
    end

    result = row.fields |> Enum.reduce([], reducer)

    case result do
      [] ->
        row |> Rows.change_ingest_sheet_row_validation_state("pass")
        "pass"

      errors ->
        row |> Rows.change_ingest_sheet_row_validation_state(%{state: "fail", errors: errors})
        "fail"
    end
  end

  defp load_sheet(sheet_id) do
    Sheet
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
          |> Sheets.list_ingest_sheet_row_counts()
          |> Enum.reduce_while(:ok, state_reducer)
      end

    {result, sheet}
  end

  defp add_file_errors(sheet, messages) do
    sheet
    |> Sheets.add_file_validation_errors_to_ingest_sheet(messages)
    |> Sheets.update_ingest_sheet_status("file_fail")
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

    {result, sheet |> Sheets.change_ingest_sheet_validation_state!(state)}
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
