defmodule Meadow.Events.FileSets.Annotations do
  @moduledoc """
  Handles events related to annotations for file sets.
  """

  alias Meadow.Data.Schemas.{FileSet, FileSetAnnotation, Work}
  alias Meadow.Notification
  alias Meadow.Repo

  use Meadow.Utils.Logging
  use WalEx.Event, name: Meadow

  import Ecto.Query, only: [from: 2]

  require Logger

  on_event(:file_set_annotations, %{}, [{__MODULE__, :notify_annotation_subscriptions}], & &1)

  def notify_annotation_subscriptions(%{type: :delete}), do: :ok

  def notify_annotation_subscriptions(%{new_record: %{id: id}, changes: %{status: _}}) do
    {annotation, file_set_id, work_id} =
      from(fsa in FileSetAnnotation,
        where: fsa.id == ^id,
        join: fs in FileSet,
        on: fs.id == fsa.file_set_id,
        join: w in Work,
        on: w.id == fs.work_id,
        select: {fsa, fs.id, w.id}
      )
      |> Repo.one()

    Notification.publish(annotation, file_set_annotation: file_set_id)
    Notification.publish(annotation, work_file_set_annotation: work_id)
  end

  def notify_annotation_subscriptions(_), do: :ok
end
