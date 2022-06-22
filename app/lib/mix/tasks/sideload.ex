defmodule Mix.Tasks.Meadow.Sideload do
  @moduledoc """
  Task for "sideloading" files via csv that skip transcoding pipeline actions.
  """

  alias Meadow.Data.FileSets
  alias Meadow.Pipeline
  alias Meadow.Utils.ChangesetErrors
  alias Meadow.Utils.Stream, as: StreamUtil

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

    csv
    |> stream()
    |> Stream.map(&load/1)
    |> Enum.into([])
    |> IO.inspect()
  end

  defp stream(source) do
    source
    |> StreamUtil.stream_from()
    |> StreamUtil.by_line()
    |> NimbleCSV.RFC4180.parse_stream()
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
          location: location(source, file_path),
          original_filename: file_set_original_filename
        },
        role: %{id: file_set_role, scheme: "FILE_SET_ROLE"}
      }
    end)
  end

  defp load(%{role: %{id: "A"}} = attrs) do
    with {:ok, file_set} <- FileSets.get_file_set(attrs.file_set_id),
         {:ok, file_set} <- FileSets.update_file_set(file_set, attrs) do
      Pipeline.kickoff(file_set, %{role: file_set.role.id, task: :sideload})
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

  defp location(source, filename) do
    with uri <- URI.parse(source) do
      Map.put(uri, :path, Path.dirname(uri.path) <> "/" <> filename)
    end
    |> URI.to_string()
  end
end
