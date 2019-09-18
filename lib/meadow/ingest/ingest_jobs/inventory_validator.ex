defmodule Meadow.Ingest.IngestJobs.InventoryValidator do
  @moduledoc """
  Validates an Inventory Sheet
  """
  alias Meadow.Ingest.IngestJobs.{IngestJob, IngestRow}
  alias Meadow.Repo
  alias NimbleCSV.RFC4180, as: CSV
  import Ecto.Query

  @headers ~w(accession_number description filename role work_accession_number)

  def async(job_id) do
    case Meadow.TaskRegistry |> Registry.lookup(job_id) do
      [{pid, _}] ->
        {:running, pid}

      _ ->
        Task.start(fn ->
          Meadow.TaskRegistry |> Registry.register(job_id, nil)
          result(job_id)
        end)
    end
  end

  def result(job) do
    validate(job)
    |> IngestJob.find_state()
  end

  def validate(job_id) when is_binary(job_id) do
    job_id
    |> load_job()
    |> validate()
  end

  def validate(%IngestJob{} = job) do
    unless Ecto.assoc_loaded?(job.project) do
      raise ArgumentError, "Ingest Job association not loaded"
    end

    events = [
      {"file", &load_file/1},
      {"headers", &validate_headers/1},
      {"rows", &validate_rows/1},
      {"overall", &overall_status/1}
    ]

    with {_, result} <- check_result(job, events), do: result
  end

  defp check_result(job, {event, func}) do
    case job |> IngestJob.find_state(event) do
      "pass" -> {:ok, job}
      "fail" -> {:error, job}
      "pending" -> job |> func.() |> update_state(event)
    end
  end

  defp check_result(job, [process | []]) do
    check_result(job, process)
  end

  defp check_result(job, [process | rest]) do
    case job |> check_result(process) do
      {:ok, result} -> result |> check_result(rest)
      {_, result} -> result |> check_result({"overall", &overall_status/1})
    end
  end

  defp load_file(job) do
    "/" <> filename = URI.parse(job.filename).path

    case Application.get_env(:meadow, :upload_bucket)
         |> ExAws.S3.get_object(filename)
         |> ExAws.request() do
      {:error, _} ->
        {:error, job}

      {:ok, obj} ->
        {:ok, job} |> update_state("file")
        load_rows(job, obj.body)
    end
  end

  defp load_rows(job, csv) do
    [headers | rows] = CSV.parse_string(csv, skip_headers: false)
    {:ok, job} |> update_state("csv")

    Repo.transaction(fn ->
      rows
      |> Enum.with_index(1)
      |> Enum.map(fn {row, row_num} ->
        now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)

        fields =
          Enum.zip(headers, row)
          |> Enum.reduce([], fn {k, v}, acc ->
            [%IngestRow.Field{header: k, value: v} | acc]
          end)
          |> Enum.reverse()

        %{
          ingest_job_id: job.id,
          row: row_num,
          fields: fields,
          state: "pending",
          inserted_at: now,
          updated_at: now
        }
      end)
      |> Enum.chunk_every(10_000)
      |> Enum.each(fn chunk ->
        Repo.insert_all(IngestRow, chunk,
          on_conflict: :replace_all_except_primary_key,
          conflict_target: [:ingest_job_id, :row]
        )
      end)
    end)

    {:ok, job}
  rescue
    NimbleCSV.ParseError -> {:error, job} |> update_state("csv")
  end

  defp validate_headers(job) do
    first_row =
      Meadow.Ingest.IngestJobs.list_ingest_rows(job: job, start: 1, limit: 1) |> List.first()

    headers = for(field <- first_row.fields, into: [], do: field.header) |> Enum.sort()

    case headers do
      @headers -> {:ok, job}
      _ -> {:error, job}
    end
  end

  defp validate_rows(job) do
    row_check = fn
      row, result ->
        case validate_row(job, row) do
          "pass" -> result
          "fail" -> :error
        end
    end

    {
      Meadow.Ingest.IngestJobs.list_ingest_rows(job: job, state: ["pending"])
      |> Enum.reduce(:ok, row_check),
      job
    }
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

  defp validate_row(job, %IngestRow{state: "pending"} = row) do
    reducer = fn %IngestRow.Field{header: field_name, value: value}, acc ->
      value =
        case {field_name, value} do
          {"filename", v} -> {"filename", job.project.folder <> "/" <> v}
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
        row |> Meadow.Ingest.IngestJobs.change_ingest_row_state("pass")
        "pass"

      errors ->
        row |> Meadow.Ingest.IngestJobs.update_ingest_row(%{state: "fail", errors: errors})
        "fail"
    end
  end

  defp load_job(job_id) do
    IngestJob
    |> where([ingest_job], ingest_job.id == ^job_id)
    |> preload(:project)
    |> Repo.one()
  end

  defp overall_status(job) do
    state_reducer = fn %{state: state, count: count}, result ->
      case {state, count} do
        {"pending", count} when count > 0 -> {:halt, :pending}
        {"fail", count} when count > 0 -> {:halt, :error}
        _ -> {:cont, result}
      end
    end

    result =
      case "fail" in (job.state |> Enum.map(& &1.state)) do
        true ->
          :error

        false ->
          job
          |> Meadow.Ingest.IngestJobs.list_ingest_job_row_counts()
          |> Enum.reduce_while(:ok, state_reducer)
      end

    {result, job}
  end

  defp update_state({result, job}, event) do
    state = %{
      String.to_atom(event) =>
        case result do
          :ok -> "pass"
          :error -> "fail"
          _ -> "pending"
        end
    }

    {result, job |> Meadow.Ingest.IngestJobs.change_ingest_job_state!(state)}
  end
end
