defmodule Meadow.ArchivesSpace do
  @moduledoc """
  The ArchivesSpace context: manages links between Meadow records
  (works and collections) and ArchivesSpace records, and tracks the
  status of metadata synchronization.
  """

  import Ecto.Query, warn: false

  alias Meadow.Data.Schemas.{ArchivesSpaceLink, Collection, Work}
  alias Meadow.Repo

  @doc "Returns all ArchivesSpace links"
  def list_links do
    Repo.all(ArchivesSpaceLink)
  end

  @doc "Returns all links currently in an error state, most recent first"
  def list_error_links do
    from(l in ArchivesSpaceLink,
      where: l.sync_status == :error,
      order_by: [desc: l.updated_at]
    )
    |> Repo.all()
  end

  @doc """
  Returns a summary of each imported ArchivesSpace resource, most recent first

  An import is a collection-linked resource (a finding aid brought into
  Meadow). Each summary carries the linked collection, the finding aid URL,
  the sync status, and a count of works in the collection — enough to drive
  the ArchivesSpace imports dashboard.
  """
  def list_imports do
    from(l in ArchivesSpaceLink,
      where: not is_nil(l.collection_id),
      order_by: [desc: l.inserted_at]
    )
    |> Repo.all()
    |> Enum.map(&import_summary/1)
  end

  defp import_summary(%ArchivesSpaceLink{} = link) do
    collection = link.collection_id && Repo.get(Collection, link.collection_id)

    %{
      id: link.id,
      archives_space_uri: link.archives_space_uri,
      sync_status: link.sync_status,
      inserted_at: link.inserted_at,
      collection: collection,
      finding_aid_url: collection && collection.finding_aid_url,
      work_count: work_count(link.collection_id)
    }
  end

  defp work_count(nil), do: 0

  defp work_count(collection_id) do
    from(w in Work, where: w.collection_id == ^collection_id)
    |> Repo.aggregate(:count)
  end

  @doc "Gets a link by id, raising if not found"
  def get_link!(id), do: Repo.get!(ArchivesSpaceLink, id)

  @doc "Gets the link for a work (or work id), or nil"
  def get_link_for_work(%Work{id: id}), do: get_link_for_work(id)

  def get_link_for_work(work_id) do
    Repo.get_by(ArchivesSpaceLink, work_id: work_id)
  end

  @doc "Gets the link for a collection (or collection id), or nil"
  def get_link_for_collection(%Collection{id: id}), do: get_link_for_collection(id)

  def get_link_for_collection(collection_id) do
    Repo.get_by(ArchivesSpaceLink, collection_id: collection_id)
  end

  @doc "Gets the collection link for an ArchivesSpace resource URI, or nil"
  def get_collection_link_for_uri(archives_space_uri) do
    from(l in ArchivesSpaceLink,
      where: l.archives_space_uri == ^archives_space_uri and not is_nil(l.collection_id)
    )
    |> Repo.one()
  end

  @doc "Checks whether any work is linked to the given ArchivesSpace URI"
  def work_linked_to_uri?(archives_space_uri) do
    from(l in ArchivesSpaceLink,
      where: l.archives_space_uri == ^archives_space_uri and not is_nil(l.work_id)
    )
    |> Repo.exists?()
  end

  @doc """
  Links a work to an ArchivesSpace record (typically an archival object)

  ## Examples

      iex> link_work(work, "/repositories/2/archival_objects/1234")
      {:ok, %ArchivesSpaceLink{}}
  """
  def link_work(work, archives_space_uri, attrs \\ %{})

  def link_work(%Work{id: id}, archives_space_uri, attrs),
    do: link_work(id, archives_space_uri, attrs)

  def link_work(work_id, archives_space_uri, attrs) do
    attrs
    |> Enum.into(%{work_id: work_id, archives_space_uri: archives_space_uri})
    |> create_link()
  end

  @doc """
  Links a collection to an ArchivesSpace record (typically a resource)
  """
  def link_collection(collection, archives_space_uri, attrs \\ %{})

  def link_collection(%Collection{id: id}, archives_space_uri, attrs),
    do: link_collection(id, archives_space_uri, attrs)

  def link_collection(collection_id, archives_space_uri, attrs) do
    attrs
    |> Enum.into(%{collection_id: collection_id, archives_space_uri: archives_space_uri})
    |> create_link()
  end

  @doc "Creates a link from raw attributes"
  def create_link(attrs) do
    %ArchivesSpaceLink{}
    |> ArchivesSpaceLink.changeset(attrs)
    |> Repo.insert()
  end

  @doc "Updates a link"
  def update_link(%ArchivesSpaceLink{} = link, attrs) do
    link
    |> ArchivesSpaceLink.changeset(attrs)
    |> Repo.update()
  end

  @doc "Removes a link without touching either system's records"
  def unlink(%ArchivesSpaceLink{} = link), do: Repo.delete(link)

  @doc "Marks a link as waiting to be synced"
  def mark_pending(%ArchivesSpaceLink{} = link),
    do: update_link(link, %{sync_status: :pending})

  @doc "Marks a link as successfully synced"
  def mark_synced(%ArchivesSpaceLink{} = link, attrs \\ %{}) do
    attrs
    |> Enum.into(%{
      sync_status: :synced,
      sync_error: nil,
      last_synced_at: DateTime.utc_now()
    })
    |> then(&update_link(link, &1))
  end

  @doc "Marks a link as failed, recording the error message"
  def mark_error(%ArchivesSpaceLink{} = link, error) do
    update_link(link, %{sync_status: :error, sync_error: to_error_string(error)})
  end

  defp to_error_string(error) when is_binary(error), do: error
  defp to_error_string(error), do: inspect(error)
end
