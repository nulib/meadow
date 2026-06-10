defmodule Meadow.Events.FileSets.TranscriptionSync do
  @moduledoc """
  Syncs a file set's transcription to ArchivesSpace when it changes.

  Listens to WAL events on the `file_set_annotations` table and, when a
  completed transcription is inserted or updated, resolves the annotation's
  file set → work and schedules an ArchivesSpace sync (if the work is linked).
  This is what makes a transcription edited in Meadow appear on the work's
  digital object in ArchivesSpace. Sync runs through the same rate-limited
  `Meadow.Events.Works.ArchivesSpace.Processor` as work-metadata syncs.
  """

  alias Meadow.ArchivesSpace
  alias Meadow.Config
  alias Meadow.Data.Schemas.{FileSet, FileSetAnnotation, Work}
  alias Meadow.Events.Works.ArchivesSpace.Processor
  alias Meadow.Repo

  use Meadow.Utils.Logging
  use WalEx.Event, name: Meadow

  import Ecto.Query, only: [from: 2]

  require Logger

  on_event(:file_set_annotations, %{}, [{__MODULE__, :handle_event}], & &1)

  def handle_event(%{type: type, new_record: %{id: id, type: "transcription", status: "completed"}})
      when type in [:insert, :update] do
    if Config.archives_space_enabled?(), do: sync_linked_work(id)
  end

  def handle_event(_), do: :noop

  defp sync_linked_work(annotation_id) do
    from(fsa in FileSetAnnotation,
      where: fsa.id == ^annotation_id,
      join: fs in FileSet,
      on: fs.id == fsa.file_set_id,
      join: w in Work,
      on: w.id == fs.work_id,
      select: w.id
    )
    |> Repo.one()
    |> case do
      nil ->
        :noop

      work_id ->
        if ArchivesSpace.get_link_for_work(work_id) do
          with_log_metadata module: __MODULE__, id: work_id do
            Logger.info("Transcription changed; syncing work #{work_id} to ArchivesSpace")
            Processor.sync_work(work_id)
          end
        end
    end
  end
end
