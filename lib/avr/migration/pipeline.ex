defmodule AVR.Migration.Pipeline do
  require Logger

  alias Meadow.Repo

  import Ecto.Query

  def submit_batch(limit \\ :all) do
    batch_query(limit)
    |> Repo.all()
    |> send_to_pipeline()
    |> next(limit)
  end

  defp batch_query(:all) do
    with_most_recent_state()
    |> where([fs, as], is_nil(as.id))
  end

  defp batch_query(limit) do
    batch_query(:all)
    |> limit(^limit)
  end

  def next(:end, _), do: :noop

  def next(_, limit) do
    case file_sets_processing() do
      [] ->
        submit_batch(limit)

      processing ->
        Logger.info("Waiting for #{length(processing)} FileSets to complete")
        Process.sleep(60_000)
        next(:wait, limit)
    end
  end

  def file_sets_processing do
    with_most_recent_state()
    |> where([_, as], as.outcome in ["ok", "error"])
    |> Repo.all()
    |> Enum.map(fn file_set ->
      with [as | _] <- file_set.action_states do
        %{
          file_set_id: file_set.id,
          action: as.action,
          outcome: as.outcome,
          inserted_at: as.inserted_at,
          updated_at: as.updated_at
        }
      end
    end)
    |> Enum.reject(
      &(&1.outcome == "error" or &1.action == "Meadow.Pipeline.Actions.FileSetComplete")
    )
  end

  def send_to_pipeline([]), do: :end

  def send_to_pipeline(file_sets) do
    file_sets
    |> Task.async_stream(&Meadow.Pipeline.kickoff/1)
    |> Stream.run()
  end

  def with_most_recent_state do
    from(
      fs in AVR.Migration.avr_filesets_query(),
      left_join: as in assoc(fs, :action_states),
      on: fs.id == as.object_id,
      distinct: fs.id,
      order_by: [desc: fs.updated_at, desc: fs.id, desc: as.updated_at],
      preload: [action_states: as]
    )
  end
end
