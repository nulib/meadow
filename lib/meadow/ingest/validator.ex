defmodule Meadow.Ingest.Validator do
  @moduledoc """
  Validates an Ingest Sheet
  """

  alias Meadow.Config
  alias Meadow.Data.{CodedTerms, FileSets, Works}
  alias Meadow.Ingest.{Rows, Sheets}
  alias Meadow.Ingest.Schemas.{Row, Sheet}
  alias Meadow.Repo
  alias Meadow.Utils.{MapList, Truth}
  alias NimbleCSV.RFC4180, as: CSV
  import Ecto.Query

  use Meadow.Constants
  use Meadow.Utils.Logging

  require Logger

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
    with_log_metadata module: __MODULE__, id: sheet.id do
      Logger.info("Beginning validation for Ingest Sheet: #{sheet.id}")

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
            {:error, add_file_errors(sheet, ["Could not load ingest sheet from S3"])}

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
    case Enum.sort(headers) do
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

        file_set_accession_number = MapList.get(fields, :header, :value, :file_accession_number)

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
      |> Enum.chunk_every(5_000)
      |> Enum.each(fn chunk ->
        Repo.insert_all(Row, chunk,
          on_conflict: {:replace_all_except, [:id]},
          conflict_target: [:sheet_id, :row]
        )
      end)
    end)
  end

  defp validate_rows(sheet) do
    with rows <- Rows.list_ingest_sheet_rows(sheet: sheet, state: ["pending"]) do
      existing_files =
        Config.ingest_bucket()
        |> ExAws.S3.list_objects(prefix: sheet.project.folder)
        |> ExAws.stream!()
        |> Enum.to_list()
        |> Enum.map(fn file -> Map.get(file, :key) end)
        |> MapSet.new()

      duplicate_accession_numbers =
        rows
        |> Enum.group_by(& &1.file_set_accession_number)
        |> Enum.filter(fn {_, rows} -> length(rows) > 1 end)
        |> Enum.map(fn {accession_number, rows} ->
          {accession_number, Enum.map(rows, & &1.row)}
        end)
        |> Enum.into(%{})

      work_types =
        rows
        |> Enum.group_by(&Row.field_value(&1, "work_accession_number"))
        |> Enum.map(fn {work_accession_number, rows} ->
          values =
            Enum.map(rows, &Row.field_value(&1, "work_type"))
            |> Enum.reject(&(is_nil(&1) or &1 == ""))
            |> Enum.uniq()

          {work_accession_number, values}
        end)
        |> Enum.into(%{})

      context = %{
        project_folder: sheet.project.folder,
        existing_files: existing_files,
        duplicate_accession_numbers: duplicate_accession_numbers,
        work_types: work_types
      }

      row_check = fn
        row, result ->
          case validate_row(row, context) do
            "pass" -> result
            "fail" -> :error
          end
      end

      overall_row_result = {
        rows
        |> Enum.reduce(:ok, row_check),
        sheet
      }

      case overall_row_result do
        {:ok, sheet} ->
          Logger.info("Ingest sheet: #{sheet.id} is valid")
          Sheets.update_ingest_sheet_status(sheet, "valid")
          {:ok, sheet}

        {:error, sheet} ->
          Logger.warn("Ingest sheet: #{sheet.id} has failing rows")
          Sheets.update_ingest_sheet_status(sheet, "row_fail")
          {:error, sheet}
      end
    end
  end

  defp validate_value(row, {"work_image", value}, _context) do
    role = Row.field_value(row, "role")

    cond do
      value == "" -> :ok
      Truth.false?(value) -> :ok
      Truth.true?(value) and Enum.member?(["A", "X"], role) -> :ok
      Truth.true?(value) -> {:error, "work_image", "role #{role} cannot be a work image"}
      true -> {:error, "work_image", "boolean type required"}
    end
  end

  defp validate_value(_row, {"structure", value}, context) do
    if String.trim(value) == "" do
      :ok
    else
      case Meadow.Config.ingest_bucket()
           |> ExAws.S3.get_object("#{context.project_folder}/#{value}")
           |> ExAws.request() do
        {:ok, %{body: vtt}} ->
          if String.match?(vtt, ~r/^WEBVTT/),
            do: :ok,
            else: {:error, "structure", "#{value} is not a valid WebVTT file"}

        {:error, {:http_error, 404, _}} ->
          {:error, "structure", "Structure file #{value} not found in the ingest bucket"}

        {:error, other} ->
          {:error, "structure",
           "The following error occurred validating #{value}: #{inspect(other)}"}
      end
    end
  end

  defp validate_value(_row, {field_name, value}, _context)
       when byte_size(value) == 0,
       do: {:error, field_name, "cannot be blank"}

  defp validate_value(row, {"work_type", value}, %{work_types: work_types}) do
    work_accession_number = Row.field_value(row, "work_accession_number")
    work_type_values = Map.get(work_types, work_accession_number)

    cond do
      Enum.empty?(work_type_values) ->
        {:error, "work_type", "work #{work_accession_number} missing work_type"}

      length(work_type_values) > 1 ->
        {:error, "work_type", "work #{work_accession_number} has conflicting work_type values"}

      value == "" ->
        :ok

      CodedTerms.get_coded_term(value, "work_type") |> is_nil() ->
        {:error, "work_type", "#{value} is invalid"}

      true ->
        :ok
    end
  end

  defp validate_value(_row, {"role", value}, _context) do
    case CodedTerms.get_coded_term(value, "file_set_role") do
      {{:ok, _}, _term} ->
        :ok

      nil ->
        {:error, "role", "#{value} is invalid"}
    end
  end

  defp validate_value(
         _row,
         {"file_accession_number", value},
         %{duplicate_accession_numbers: duplicate_accession_numbers}
       ) do
    case Map.get(duplicate_accession_numbers, value) do
      nil ->
        if FileSets.accession_exists?(value),
          do: {:error, "file_accession_number", "#{value} already exists in system"},
          else: :ok

      duplicate_rows ->
        with row_list <- duplicate_rows |> Enum.map(&to_string/1) |> Enum.join(", ") do
          {:error, "file_accession_number", "#{value} is duplicated on rows #{row_list}"}
        end
    end
  end

  defp validate_value(_row, {"work_accession_number", value}, _context) do
    case Works.accession_exists?(value) do
      true ->
        {:error, "work_accession_number", "#{value} already exists in system"}

      false ->
        :ok
    end
  end

  defp validate_value(row, {"filename", value}, %{existing_files: existing_files}) do
    role = Row.field_value(row, "role")
    work_type = Row.field_value(row, "work_type")
    mime_type = MIME.from_path(value)

    cond do
      Truth.false?(MapSet.member?(existing_files, value)) ->
        {:error, "filename", "File not Found: #{value}"}

      Truth.false?(mime_type_accepted?(work_type, role, mime_type)) ->
        {:error, "filename",
         "Mime-type: #{value}, not accepted for work type: #{work_type} and file set role: #{role}."}

      true ->
        :ok
    end
  end

  defp validate_value(_row, {_field_name, _value}, _context),
    do: :ok

  defp validate_row(%Row{state: "pending"} = row, context) do
    reducer = fn %Row.Field{header: field_name, value: value}, acc ->
      case validate_value(row, {field_name, value}, context) do
        :ok -> acc
        {:error, field, error} -> [%{field: field, message: "#{field}: #{error}"} | acc]
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

  defp mime_type_accepted?(_, "X", "image/" <> _rest), do: true
  defp mime_type_accepted?(_, "S", "text/" <> _rest), do: true

  defp mime_type_accepted?(_, "S", "application/" <> rest)
       when rest in [
              "json",
              "xml",
              "pdf",
              "msword",
              "vnd.ms-excel",
              "vnd.openxmlformats-officedocument.spreadsheetml.sheet"
            ],
       do: true

  defp mime_type_accepted?("IMAGE", role, "image/" <> _rest) when role in ["A", "P"], do: true
  defp mime_type_accepted?("VIDEO", "A", "video/x-matroska"), do: false
  defp mime_type_accepted?("VIDEO", role, "video/" <> _rest) when role in ["A", "P"], do: true
  defp mime_type_accepted?("AUDIO", "A", "audio/x-aiff"), do: false
  defp mime_type_accepted?("AUDIO", "A", "audio/x-flac"), do: false
  defp mime_type_accepted?("AUDIO", role, "audio/" <> _rest) when role in ["A", "P"], do: true
  defp mime_type_accepted?(_, _, _), do: false

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
    Logger.warn("Ingest sheet: #{sheet.id} has file errors")

    {:ok, result} =
      sheet
      |> Sheets.add_file_validation_errors_to_ingest_sheet(messages)
      |> Sheets.update_ingest_sheet_status("file_fail")

    result
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
