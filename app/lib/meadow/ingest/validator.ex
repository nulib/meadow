defmodule Meadow.Ingest.Validator do
  @moduledoc """
  Validates an Ingest Sheet
  """

  alias Meadow.Config
  alias Meadow.Data.{CodedTerms, FileSets, Works}
  alias Meadow.Ingest.{Rows, Sheets}
  alias Meadow.Ingest.Schemas.{Row, Sheet}
  alias Meadow.Repo
  alias Meadow.Utils.{AWS, MapList, MIME, Truth}
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
            :timer.sleep(@sleep_time * trunc(:math.pow(2, i - 1)))
            load_file(sheet, i + 1)
        end

      {:ok, obj} ->
        load_rows(sheet, obj.body)
    end
  end

  def load_rows(sheet, csv) do
    [headers | rows] = CSV.parse_string(csv, skip_headers: false)

    case sheet |> validate_headers(headers) do
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
    valid_headers = @ingest_sheet_headers ++ @ingest_sheet_optional_headers
    missing = check_missing_headers(@ingest_sheet_headers -- headers)
    invalid = check_invalid_headers(headers -- valid_headers)

    case missing ++ invalid do
      [] ->
        {:ok, sheet}

      errors ->
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
    all_rows = Rows.list_ingest_sheet_rows(sheet: sheet)
    pending_rows = Enum.filter(all_rows, &(&1.state == "pending"))

    existing_files =
      Config.ingest_bucket()
      |> ExAws.S3.list_objects(prefix: sheet.project.folder)
      |> ExAws.stream!()
      |> Enum.to_list()
      |> Enum.map(fn file -> Map.get(file, :key) end)
      |> MapSet.new()

    duplicate_accession_numbers =
      all_rows
      |> Enum.group_by(& &1.file_set_accession_number)
      |> Enum.filter(fn {_, rows} -> length(rows) > 1 end)
      |> Enum.map(fn {accession_number, rows} ->
        {accession_number, Enum.map(rows, & &1.row)}
      end)
      |> Enum.into(%{})

    work_types =
      all_rows
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
      work_types: work_types,
      tag_cache: fetch_tag_cache(pending_rows),
      structure_cache: fetch_structure_cache(pending_rows, sheet.project.folder)
    }

    initial_result = if Enum.any?(all_rows, &(&1.state == "fail")), do: :error, else: :ok

    {row_result, crash_count} =
      pending_rows
      |> Task.async_stream(&validate_row(&1, context),
        max_concurrency: 20,
        timeout: 30_000,
        on_timeout: :kill_task
      )
      |> Enum.reduce({initial_result, 0}, fn
        {:ok, "pass"}, {acc, crashes} ->
          {acc, crashes}

        {:ok, "fail"}, {_, crashes} ->
          {:error, crashes}

        {:exit, reason}, {acc, crashes} ->
          Logger.error("Row validation task crashed: #{inspect(reason)}")
          {acc, crashes + 1}
      end)

    case {row_result, crash_count} do
      {_, n} when n > 0 ->
        {:incomplete, sheet}

      {:ok, 0} ->
        Logger.info("Ingest sheet: #{sheet.id} is valid")
        Sheets.update_ingest_sheet_status(sheet, "valid")
        {:ok, sheet}

      {:error, 0} ->
        Logger.warning("Ingest sheet: #{sheet.id} has failing rows")
        Sheets.update_ingest_sheet_status(sheet, "row_fail")
        {:error, sheet}
    end
  end

  defp fetch_tag_cache(rows) do
    rows
    |> Enum.map(&Row.field_value(&1, "filename"))
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
    |> Task.async_stream(&{&1, check_tags(&1)},
      max_concurrency: 20,
      timeout: 30_000,
      on_timeout: :kill_task
    )
    |> Enum.reduce(%{}, fn
      {:ok, {path, result}}, acc -> Map.put(acc, path, result)
      {:exit, _}, acc -> acc
    end)
  end

  defp check_tags(path) do
    case ExAws.S3.get_object_tagging(Config.ingest_bucket(), path) |> ExAws.request() do
      {:ok, %{status_code: 200, body: %{tags: actual_tags}}} ->
        existing = Enum.map(actual_tags, &Map.get(&1, :key))
        Config.required_checksum_tags() -- existing == []

      {:error, {:http_error, 404, _}} ->
        false

      other ->
        raise "Unexpected response checking tags for #{path}: #{inspect(other)}"
    end
  end

  defp fetch_structure_cache(rows, project_folder) do
    rows
    |> Enum.map(&Row.field_value(&1, "structure"))
    |> Enum.reject(&(is_nil(&1) || String.trim(&1) == ""))
    |> Enum.uniq()
    |> Task.async_stream(
      fn name ->
        result =
          Config.ingest_bucket()
          |> ExAws.S3.get_object("#{project_folder}/#{name}")
          |> ExAws.request()

        {name, result}
      end,
      max_concurrency: 20,
      timeout: 30_000,
      on_timeout: :kill_task
    )
    |> Enum.reduce(%{}, fn
      {:ok, {name, result}}, acc -> Map.put(acc, name, result)
      {:exit, _}, acc -> acc
    end)
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

  defp validate_value(row, {"structure", value}, context) do
    if String.trim(value) == "" do
      :ok
    else
      work_type = Row.field_value(row, "work_type")

      s3_result =
        case Map.fetch(context.structure_cache, value) do
          {:ok, cached} ->
            cached

          :error ->
            Config.ingest_bucket()
            |> ExAws.S3.get_object("#{context.project_folder}/#{value}")
            |> ExAws.request()
        end

      validate_structure_value(s3_result, value, work_type)
    end
  end

  defp validate_value(_row, {"add_to_existing", value}, _context) do
    cond do
      value in ["", nil] -> :ok
      Truth.true?(value) -> :ok
      Truth.false?(value) -> :ok
      true -> {:error, "add_to_existing", "boolean type required"}
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
          else: ensure_trimmed(value, "file_accession_number")

      duplicate_rows ->
        with row_list <- duplicate_rows |> Enum.map_join(", ", &to_string/1) do
          {:error, "file_accession_number", "#{value} is duplicated on rows #{row_list}"}
        end
    end
  end

  defp validate_value(row, {"work_accession_number", value}, _context) do
    add_to_existing = row |> Row.field_value("add_to_existing") |> Truth.true?()

    case {Works.accession_exists?(value), add_to_existing} do
      {true, false} -> {:error, "work_accession_number", "#{value} already exists in system"}
      {false, true} -> {:error, "work_accession_number", "#{value} does not exist in system"}
      _ -> ensure_trimmed(value, "work_accession_number")
    end
  end

  defp validate_value(row, {"filename", value}, %{
         existing_files: existing_files,
         tag_cache: tag_cache
       }) do
    role = Row.field_value(row, "role")
    work_type = Row.field_value(row, "work_type")
    mime_type = MIME.from_path(value)

    unsafe_chars =
      ~r/[^a-zA-Z0-9!\-_.*'()\/]/
      |> Regex.scan(value)
      |> List.flatten()
      |> Enum.uniq()

    cond do
      unsafe_chars != [] ->
        {:error, "filename",
         "#{value} contains characters that are not safe for S3 object keys: #{Enum.join(unsafe_chars, ", ")}"}

      Truth.false?(MapSet.member?(existing_files, value)) ->
        {:error, "filename", "File not Found: #{value}"}

      Truth.false?(mime_type_accepted?(work_type, role, mime_type)) ->
        {:error, "filename",
         "Mime-type: #{value}, not accepted for work type: #{work_type} and file set role: #{role}."}

      true ->
        has_tags =
          case Map.fetch(tag_cache, value) do
            {:ok, result} ->
              result

            :error ->
              AWS.check_object_tags!(
                Config.ingest_bucket(),
                value,
                Config.required_checksum_tags()
              )
          end

        if has_tags,
          do: :ok,
          else: {:error, "filename", "#{value} missing computed-md5 tag"}
    end
  end

  defp validate_value(_row, {_field_name, _value}, _context),
    do: :ok

  defp ensure_trimmed(value, field_name) do
    if String.trim(value) == value,
      do: :ok,
      else: {:error, field_name, "cannot have leading or trailing spaces"}
  end

  defp validate_structure_value({:ok, %{body: content}}, value, work_type) do
    extension = Path.extname(value) |> String.downcase()
    validate_structure_extension(extension, work_type, content, value)
  end

  defp validate_structure_value({:error, {:http_error, 404, _}}, value, _work_type) do
    {:error, "structure", "Structure file #{value} not found in the ingest bucket"}
  end

  defp validate_structure_value({:error, other}, value, _work_type) do
    {:error, "structure", "The following error occurred validating #{value}: #{inspect(other)}"}
  end

  defp validate_structure_extension(".txt", "IMAGE", _content, _value), do: :ok

  defp validate_structure_extension(".vtt", work_type, content, value)
       when work_type in ["AUDIO", "VIDEO"] do
    if String.match?(content, ~r/^WEBVTT/),
      do: :ok,
      else: {:error, "structure", "#{value} is not a valid WebVTT file"}
  end

  defp validate_structure_extension(".vtt", "IMAGE", _content, _value) do
    {:error, "structure", "IMAGE works must use .txt files for transcriptions, not .vtt files"}
  end

  defp validate_structure_extension(".txt", work_type, _content, _value)
       when work_type in ["AUDIO", "VIDEO"] do
    {:error, "structure", "#{work_type} works must use .vtt files for structure, not .txt files"}
  end

  defp validate_structure_extension(extension, work_type, _content, _value) do
    {:error, "structure",
     "Invalid structure file extension #{extension} for work type #{work_type}"}
  end

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
  defp mime_type_accepted?(_, "X", "application/pdf"), do: true
  defp mime_type_accepted?(_, "X", "application/zip"), do: true
  defp mime_type_accepted?(_, "X", "application/zip" <> _rest), do: true

  defp mime_type_accepted?(_, "P", _), do: true
  defp mime_type_accepted?(_, "S", _), do: true

  defp mime_type_accepted?("IMAGE", "A", "image/" <> _rest), do: true
  defp mime_type_accepted?("VIDEO", "A", "video/x-matroska"), do: false
  defp mime_type_accepted?("VIDEO", "A", "video/x-vob"), do: false
  defp mime_type_accepted?("VIDEO", "A", "video/x-mts"), do: false
  defp mime_type_accepted?("VIDEO", "A", "video/" <> _rest), do: true
  defp mime_type_accepted?("AUDIO", "A", "audio/x-aiff"), do: false
  defp mime_type_accepted?("AUDIO", "A", "audio/x-flac"), do: false
  defp mime_type_accepted?("AUDIO", "A", "audio/" <> _rest), do: true
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
    Logger.warning("Ingest sheet: #{sheet.id} has file errors")

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
