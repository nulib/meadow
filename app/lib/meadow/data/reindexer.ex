defmodule Meadow.Data.Reindexer do
  @moduledoc """
  Reindexes from v1 to v2 using the OpenSearch Reindex API.
  """
  use Meadow.Utils.Logging

  alias Meadow.Config
  alias Meadow.Data.Schemas.{Collection, FileSet, Work}
  alias Meadow.Search.Client, as: SearchClient

  require Logger

  def synchronize(tasks) do
    with_log_metadata module: __MODULE__ do
      [FileSet, Work, Collection]
      |> Enum.map(&process_schema(&1, Map.get(tasks, &1, nil)))
      |> Enum.into(%{})
    end
  end

  defp process_schema(schema, task_id) do
    if SearchClient.task_completed?(task_id) do
      synchronize_schema(schema)
    else
      {schema, task_id}
    end
  end

  defp synchronize_schema(schema) do
    destination = Config.v2_index(schema)

    case SearchClient.latest_v2_indexed_time(schema) do
      {:ok, indexed_at} ->
        case SearchClient.reindex(schema, indexed_at) do
          {:ok, task} ->
            Logger.info(
              "Documents newer than #{indexed_at} reindexing into #{destination}, task: #{task}"
            )

            {schema, task}

          {:error, error} ->
            Logger.error("Error reindexing into #{destination}: #{inspect(error)}")
            {schema, nil}
        end

      {:error, error} ->
        Logger.error("Error reindexing into #{destination}: #{inspect(error)}")
        {schema, nil}
    end
  end
end
