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

  def notify_annotation_subscriptions(%{old_record: %{s3_location: s3_object}, type: :delete})
      when is_binary(s3_object) do
    Logger.info("Deleting annotation S3 object: #{s3_object}")
    %{host: bucket, path: "/" <> key} = URI.parse(s3_object)
    ExAws.S3.delete_object(bucket, key) |> ExAws.request()
  end

  def notify_annotation_subscriptions(%{new_record: %{id: id} = record, changes: %{status: _}}) do
    from(fsa in FileSetAnnotation,
      where: fsa.id == ^id,
      left_join: fs in FileSet,
      on: fs.id == fsa.file_set_id,
      left_join: w in Work,
      on: w.id == fs.work_id,
      select: {fsa, fs.id, w.id}
    )
    |> Repo.one()
    |> case do
      nil ->
        :noop

      {annotation, file_set_id, work_id} ->
        if not is_nil(file_set_id),
          do: Notification.publish(annotation, file_set_annotation: file_set_id)

        if not is_nil(work_id),
          do: Notification.publish(annotation, work_file_set_annotation: work_id)
    end
  end

  def notify_annotation_subscriptions(message), do: :ok
end
