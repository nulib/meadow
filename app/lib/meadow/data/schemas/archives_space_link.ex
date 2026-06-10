defmodule Meadow.Data.Schemas.ArchivesSpaceLink do
  @moduledoc """
  Links a Meadow Work or Collection to an ArchivesSpace record.

  A link targets exactly one Work (typically linked to an ArchivesSpace
  archival object) or one Collection (typically linked to a resource).
  `work_id` and `collection_id` are plain UUID columns rather than foreign
  keys so that a link outlives the deletion of its target: the remote
  cleanup in ArchivesSpace happens asynchronously, and failed cleanups
  remain visible as `:error` links after the Work is gone.

  ## Fields

  - `archives_space_uri` - the ArchivesSpace record URI, e.g.
    `/repositories/2/archival_objects/1234`
  - `ref_id` - the archival object's `ref_id`, useful for matching during ingest
  - `repository_id` - the ArchivesSpace repository id, derived from the URI
  - `digital_object_uri` - the digital object Meadow creates and manages in
    ArchivesSpace to point back at the published work
  - `sync_status` - `:linked` (never synced), `:pending`, `:synced`, or `:error`
  - `sync_error` - failure message when `sync_status` is `:error`
  - `last_synced_at` - timestamp of the last successful sync
  """
  use Ecto.Schema

  import Ecto.Changeset

  @statuses [:linked, :pending, :synced, :error]
  @uri_format ~r{^/repositories/(\d+)/(archival_objects|resources)/\d+$}

  @primary_key {:id, Ecto.UUID, autogenerate: false, read_after_writes: true}
  @foreign_key_type Ecto.UUID
  @timestamps_opts [type: :utc_datetime_usec]
  schema "archives_space_links" do
    field(:work_id, Ecto.UUID)
    field(:collection_id, Ecto.UUID)
    field(:archives_space_uri, :string)
    field(:ref_id, :string)
    field(:repository_id, :integer)
    field(:digital_object_uri, :string)
    field(:sync_status, Ecto.Enum, values: @statuses, default: :linked)
    field(:sync_error, :string)
    field(:last_synced_at, :utc_datetime_usec)

    timestamps()
  end

  def statuses, do: @statuses

  def changeset(link, attrs) do
    link
    |> cast(attrs, [
      :work_id,
      :collection_id,
      :archives_space_uri,
      :ref_id,
      :digital_object_uri,
      :sync_status,
      :sync_error,
      :last_synced_at
    ])
    |> validate_required([:archives_space_uri])
    |> validate_format(:archives_space_uri, @uri_format,
      message: "must look like /repositories/:repo_id/archival_objects/:id"
    )
    |> put_repository_id()
    |> validate_target()
    |> unique_constraint(:work_id)
    |> unique_constraint(:collection_id)
    |> check_constraint(:work_id,
      name: :work_or_collection,
      message: "link cannot target both a work and a collection"
    )
  end

  defp put_repository_id(changeset) do
    case get_field(changeset, :archives_space_uri) do
      nil ->
        changeset

      uri ->
        case Regex.run(@uri_format, uri) do
          [_, repo_id, _] -> put_change(changeset, :repository_id, String.to_integer(repo_id))
          _ -> changeset
        end
    end
  end

  defp validate_target(changeset) do
    work_id = get_field(changeset, :work_id)
    collection_id = get_field(changeset, :collection_id)

    cond do
      not is_nil(work_id) and not is_nil(collection_id) ->
        add_error(changeset, :work_id, "link cannot target both a work and a collection")

      is_nil(work_id) and is_nil(collection_id) ->
        add_error(changeset, :work_id, "link must target a work or a collection")

      true ->
        changeset
    end
  end
end
