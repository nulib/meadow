defmodule Mix.Tasks.Meadow.Sideload do
  @moduledoc """
  Task for "sideloading" files via csv that skip transcoding pipeline actions.
  """

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
    |> Stream.each(&load/1)
    |> Stream.run()
  end

  defp stream(source) do
    source
    |> StreamUtil.stream_from()
    |> StreamUtil.by_line()
    |> NimbleCSV.RFC4180.parse_stream()
    |> Stream.map(fn [
                       work_type,
                       work_accession_number,
                       file_accession_number,
                       filename,
                       description,
                       role,
                       label,
                       work_image,
                       structure
                     ] ->
      %{
        work_type: work_type,
        work_accession_number: work_accession_number,
        accession_number: file_accession_number,
        core_metadata: %{
          description: description,
          label: label,
          location: location(source, filename),
          original_filename: Path.basename(filename)
        },
        role: %{id: role, scheme: "FILE_SET_ROLE"},
        work_image: work_image,
        structure: structure
      }
      |> then(fn data ->
        work =
          Meadow.Repo.get_by(Meadow.Data.Schemas.Work,
            accession_number: data.work_accession_number
          )

        if work, do: Map.put(data, :work_id, work.id), else: data
      end)
    end)
  end

  defp load(%{role: %{id: "S"}, work_id: _} = attrs) do
    case Pipeline.ingest_file_set(attrs) do
      {:error, changeset} ->
        IO.inspect(
          "Error sideloading #{attrs.accession_number}: #{inspect(ChangesetErrors.humanize_errors(changeset))}"
        )

      {:ok, file_set} ->
        IO.inspect({:ok, file_set})
    end
  end

  defp load(_supplemental) do
    Logger.warn("Attempted to sideload a non-\"S\" file")
  end

  defp location(source, filename) do
    with uri <- URI.parse(source) do
      Map.put(uri, :path, Path.dirname(uri.path) <> "/" <> filename)
    end
    |> URI.to_string()
  end
end
