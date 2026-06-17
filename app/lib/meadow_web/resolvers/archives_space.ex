defmodule MeadowWeb.Resolvers.ArchivesSpace do
  @moduledoc """
  Resolver for ArchivesSpace links and synchronization
  """

  alias Meadow.ArchivesSpace
  alias Meadow.ArchivesSpace.{Client, ImportPreview, Importer, Sync}
  alias Meadow.Roles
  alias Meadow.Utils.ChangesetErrors

  def link_for_work(%{id: work_id}, _args, _resolution) do
    {:ok, ArchivesSpace.get_link_for_work(work_id)}
  end

  def link(_, %{work_id: work_id}, _) do
    {:ok, ArchivesSpace.get_link_for_work(work_id)}
  end

  def error_links(_, _, _) do
    {:ok, ArchivesSpace.list_error_links()}
  end

  def link_work(_, %{work_id: work_id, archives_space_uri: uri} = args, _) do
    case ArchivesSpace.link_work(work_id, uri, Map.take(args, [:ref_id])) do
      {:ok, link} ->
        {:ok, link}

      {:error, changeset} ->
        {:error,
         message: "Could not link work to ArchivesSpace",
         details: ChangesetErrors.humanize_errors(changeset)}
    end
  end

  def unlink_work(_, %{work_id: work_id}, _) do
    case ArchivesSpace.get_link_for_work(work_id) do
      nil -> {:error, "Work is not linked to ArchivesSpace"}
      link -> ArchivesSpace.unlink(link)
    end
  end

  def sync_work(_, %{work_id: work_id}, _) do
    case Sync.sync_work(work_id) do
      {:ok, link} -> {:ok, link}
      :noop -> {:error, "Work is not linked to ArchivesSpace"}
      {:error, reason} -> {:error, "Sync failed: #{inspect(reason)}"}
    end
  end

  def imports(_, _, _) do
    {:ok, ArchivesSpace.list_imports()}
  end

  def search_resources(_, %{query: query} = args, _) do
    case Client.search_resources(query, Map.get(args, :page, 1)) do
      {:ok, result} ->
        {:ok, Map.update!(result, :results, &Enum.map(&1, fn hit -> with_validation(hit) end))}

      {:error, reason} ->
        {:error, "ArchivesSpace search failed: #{inspect(reason)}"}
    end
  end

  defp with_validation(%{uri: uri} = hit) do
    validation =
      case ArchivesSpace.validate_import_resource(uri) do
        {:ok, validation} ->
          validation

        {:error, reason} ->
          %{
            importable: false,
            blocked_reason: "Could not validate this ArchivesSpace resource: #{inspect(reason)}",
            blocked_count: 0,
            blocked_samples: []
          }
      end

    Map.put(hit, :import_validation, validation)
  end

  def start_import_preview(_, %{resource_uri: resource_uri}, %{context: %{current_user: user}}) do
    if Roles.authorized?(user, :supermanager) do
      case ArchivesSpace.ensure_import_resource_importable(resource_uri) do
        :ok ->
          token = ImportPreview.start(resource_uri)
          {:ok, %{token: token, status: :pending, previews: []}}

        {:error, reason} ->
          {:error, reason}
      end
    else
      {:error, "Not authorized to generate AI import previews"}
    end
  end

  def import_resource(_, %{resource_uri: resource_uri} = args, %{context: %{current_user: user}}) do
    ai_ingest = Map.get(args, :ai_ingest, false) and Roles.authorized?(user, :supermanager)

    case Importer.import_resource_async(resource_uri, ai_ingest: ai_ingest) do
      {:ok, collection} -> {:ok, collection}
      {:error, reason} when is_binary(reason) -> {:error, reason}
      {:error, reason} -> {:error, "Import failed: #{inspect(reason)}"}
    end
  end
end
