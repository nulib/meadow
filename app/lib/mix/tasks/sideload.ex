defmodule Mix.Tasks.Meadow.Sideload do
  @moduledoc """
  Task for "sideloading" files via csv that skip transcoding pipeline actions.
  """

  alias Meadow.Data.FileSets
  alias Meadow.Pipeline
  alias Meadow.Utils.ChangesetErrors
  alias Meadow.Utils.Stream, as: StreamUtil
  alias NimbleCSV.RFC4180, as: CSV

  use Mix.Task
  require Logger

  @shortdoc @moduledoc
  def run([csv]) do
    System.put_env("MEADOW_PROCESSES", "none")
    Mix.Task.run("app.start")

    Logger.configure(level: :info)

    unless StreamUtil.exists?(csv) do
      Logger.warn("csv file #{csv} not found.")
      exit(:shutdown)
    end

    Logger.info("Beginning to sideload #{csv}")

    csv
    |> stream()
    |> Stream.map(&load/1)
    |> generate_report()
    |> upload_report()

    Logger.info("Completed sideloading #{csv}")
  end

  defp stream(source) do
    source
    |> StreamUtil.stream_from()
    |> StreamUtil.by_line()
    |> CSV.parse_stream()
    |> Stream.reject(fn x -> x == [""] end)
    |> Stream.map(fn [
                       _collection_title,
                       _meadow_url,
                       work_id,
                       _work_accession,
                       _work_title,
                       file_set_id,
                       file_set_accession,
                       file_set_role,
                       file_set_original_filename,
                       file_set_label,
                       file_set_description,
                       file_path
                     ] ->
      %{
        work_id: work_id,
        accession_number: file_set_accession,
        file_set_id: file_set_id,
        core_metadata: %{
          description: file_set_description,
          label: file_set_label,
          location: preservation_uri(source, file_path),
          original_filename: file_set_original_filename
        },
        role: %{id: file_set_role, scheme: "FILE_SET_ROLE"}
      }
    end)
  end

  defp load(%{role: %{id: "A"}} = attrs) do
    with file_set <- FileSets.get_file_set(attrs.file_set_id),
         {:ok, updated_file_set} <- FileSets.update_file_set(file_set, attrs) do
      Pipeline.kickoff(updated_file_set, %{role: updated_file_set.role.id, task: :sideload})
      Map.put(attrs, :kickoff, :success)
    else
      _ -> Map.put(attrs, :kickoff, :failure)
    end
  end

  defp load(attrs) do
    case FileSets.create_file_set(attrs) do
      {:ok, file_set} ->
        Pipeline.kickoff(file_set, %{role: file_set.role.id})
        Map.put(attrs, :kickoff, :success)

      {:error, changeset} ->
        error = inspect(ChangesetErrors.humanize_errors(changeset))
        Logger.warn("Error sideloading #{attrs.accession_number}: #{error}")
        Map.put(attrs, :kickoff, :failure)
    end
  end

  defp preservation_uri(source, filename) do
    with uri <- URI.parse(source) do
      Map.put(uri, :path, Path.dirname(uri.path) <> "/" <> filename)
    end
    |> URI.to_string()
  end

  defp generate_report(data) do
    Enum.reduce(data, [], fn x, acc ->
      [
        Map.take(x, ~W|file_set_id work_id kickoff|a)
        |> Map.values()
        | acc
      ]
    end)
    |> CSV.dump_to_stream()
    |> Enum.join("")
  end

  defp upload_report(report) do
    ExAws.S3.put_object(
      Meadow.Config.ingest_bucket(),
      "report_#{DateTime.to_unix(DateTime.utc_now())}.csv",
      report
    )
    |> ExAws.request!()
  end
end
