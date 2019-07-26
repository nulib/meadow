defmodule Meadow.Ingest.InventoryValidator do
  @moduledoc """
  Validates an Inventory Sheet
  """
  alias Meadow.Ingest.IngestJob
  alias Meadow.Notification
  alias Meadow.Repo
  alias NimbleCSV.RFC4180, as: CSV
  import Ecto.Query

  def validate(job_id) do
    IngestJob
    |> where([ingest_job], ingest_job.id == ^job_id)
    |> preload(:project)
    |> Repo.one()
    |> validate_job()
  end

  def validate_job(job) do
    unless Ecto.assoc_loaded?(job.project) do
      raise ArgumentError, "Ingest Job association not loaded"
    end

    "/" <> filename = URI.parse(job.filename).path

    case load_file(filename) do
      {:ok, obj} ->
        validate_content(job, obj.body)

      {:error, _} ->
        job_id(job)
        |> Notification.update({:csv}, %{status: "fail"})
        |> Notification.update({"job"}, %{status: "fail"})

        :fail
    end
  end

  def validate_content(job, csv) do
    [headers | rows] = CSV.parse_string(csv, skip_headers: false)
    job_id(job) |> Notification.update({:csv}, %{status: "pass"})

    rows =
      rows
      |> Enum.map(fn row -> Enum.zip(headers, row) end)

    case headers do
      ~w(work_accession_number accession_number filename description) ->
        job_id(job) |> Notification.update({:headers}, %{status: "pass"})
        validate_rows(job, rows)

      _ ->
        job_id(job)
        |> Notification.update({:headers}, %{status: "fail"})
        |> Notification.update({"job"}, %{status: "fail"})

        :fail
    end
  rescue
    NimbleCSV.ParseError ->
      job_id(job)
      |> Notification.update({:csv}, %{status: "fail"})
      |> Notification.update({"job"}, %{status: "fail"})

      :fail
  end

  defp load_file(filename) do
    Application.get_env(:meadow, :upload_bucket)
    |> ExAws.S3.get_object(filename)
    |> ExAws.request()
  end

  defp validate_value({field_name, value}) when byte_size(value) == 0,
    do: {:error, "#{field_name} cannot be blank"}

  defp validate_value({"filename", value}) do
    response =
      Application.get_env(:meadow, :ingest_bucket)
      |> ExAws.S3.head_object(value)
      |> ExAws.request()

    case response do
      {:ok, %{status_code: 200}} -> :ok
      {:error, {:http_error, 404, _}} -> {:error, "File not Found: #{value}"}
      {:error, {:http_error, code, _}} -> {:error, "Status: #{code}"}
    end
  end

  defp validate_value({_field_name, _value}), do: :ok

  defp validate_row(job, row, row_num) do
    reducer = fn tuple, acc ->
      value =
        case tuple do
          {"filename", v} -> {"filename", job.project.folder <> "/" <> v}
          other -> other
        end

      case validate_value(value) do
        :ok -> acc
        {:error, error} -> [error | acc]
      end
    end

    result = row |> Enum.reduce([], reducer)

    case result do
      [] ->
        job_id(job) |> Notification.update({:row, row_num}, %{status: "pass"})
        :pass

      errors ->
        job_id(job)
        |> Notification.update({:row, row_num}, %{
          status: "fail",
          errors: Enum.reverse(errors)
        })

        :fail
    end
  end

  defp validate_rows(job, rows) do
    rows
    |> Enum.with_index()
    |> Enum.each(fn {row, row_num} ->
      job_id(job) |> Notification.update({:row, row_num}, %{content: Enum.into(row, %{})})
    end)

    final_status = validate_rows(job, rows, 0)
    job_id(job) |> Notification.update({"job"}, %{status: to_string(final_status)})
    final_status
  end

  defp validate_rows(job, [row | []], row_num), do: validate_row(job, row, row_num)

  defp validate_rows(job, [row | rest], row_num) do
    row_status = validate_row(job, row, row_num)

    case validate_rows(job, rest, row_num + 1) do
      :fail -> :fail
      :pass -> row_status
    end
  end

  defp job_id(job), do: "job:" <> job.id
end
