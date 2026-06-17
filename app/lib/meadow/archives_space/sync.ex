defmodule Meadow.ArchivesSpace.Sync do
  @moduledoc """
  Pushes linked Meadow works to ArchivesSpace

  For a linked work, a sync:

  1. Finds or creates ArchivesSpace subject records for the work's
     controlled subject and genre terms (deduplicated on `authority_id` by
     letting ArchivesSpace report the conflicting record)
  2. Finds or creates ArchivesSpace agent records for the work's creators
     and contributors, returned as linked-agent entries
  3. Creates or updates the digital object Meadow manages for the work,
     pointing at its Digital Collections URL
  4. Reconciles the work's access file sets to digital_object_components
     under that digital object (label, IIIF image, and transcription note),
     keyed idempotently by `component_id == file_set.id`
  5. Fetches the linked archival object fresh (for its current
     `lock_version`), merges the work's synced fields (title, notes,
     subjects, linked agents, dates, language materials, digital object
     instance) into it via `Meadow.ArchivesSpace.Mapper`, and posts it
     back, retrying on optimistic-locking conflicts

  Results are recorded on the work's `ArchivesSpaceLink` (`:synced` or
  `:error` plus a message). Deleting a work removes the Meadow-managed
  digital object but never touches the archival object's description.
  """

  alias Meadow.ArchivesSpace
  alias Meadow.ArchivesSpace.{Client, Mapper}
  alias Meadow.Data.{FileSets, Works}

  use Meadow.Utils.Logging

  require Logger

  @lock_conflict_attempts 3

  @doc """
  Syncs a linked work's metadata to ArchivesSpace

  Returns `:noop` if the work has no link (or no longer exists),
  `{:ok, link}` on success, and `{:error, reason}` after recording the
  failure on the link.
  """
  def sync_work(work_id) do
    with_log_metadata module: __MODULE__, id: work_id do
      case {ArchivesSpace.get_link_for_work(work_id), Works.get_work(work_id)} do
        {nil, _} ->
          :noop

        {_, nil} ->
          :noop

        {link, work} ->
          Logger.info(
            "Syncing work #{work.id} to ArchivesSpace record #{link.archives_space_uri}"
          )

          do_sync(link, work)
      end
    end
  end

  @doc """
  Handles the deletion of a linked work

  Removes the digital object Meadow created in ArchivesSpace (the archival
  object and its description are always preserved), then removes the link.
  On failure the link is kept in an `:error` state so the failed cleanup
  stays visible.
  """
  def remove_work(work_id) do
    with_log_metadata module: __MODULE__, id: work_id do
      case ArchivesSpace.get_link_for_work(work_id) do
        nil ->
          :noop

        link ->
          Logger.info("Removing ArchivesSpace digital object for deleted work #{work_id}")

          case delete_digital_object(link) do
            :ok ->
              ArchivesSpace.unlink(link)

            {:error, reason} ->
              ArchivesSpace.mark_error(link, reason)
              {:error, reason}
          end
      end
    end
  end

  defp do_sync(link, work) do
    with {:ok, subject_refs} <- ensure_subjects(work),
         {:ok, linked_agents} <- ensure_agents(work),
         {:ok, link} <- ensure_digital_object(link, work),
         {:ok, component_state} <- sync_components(link, work),
         {:ok, _record, work_state} <-
           update_archival_object(link, work, subject_refs, linked_agents) do
      ArchivesSpace.mark_synced(link, %{sync_state: Map.merge(work_state, component_state)})
    else
      {:error, reason} ->
        Logger.error("ArchivesSpace sync failed for work #{work.id}: #{inspect(reason)}")
        ArchivesSpace.mark_error(link, reason)
        {:error, reason}
    end
  end

  # Topical subjects and genres both become ArchivesSpace subjects (genres
  # carry a genre_form term type), deduplicated on authority_id by letting
  # ArchivesSpace report the conflicting record.
  defp ensure_subjects(work) do
    subjects = Enum.map(work.descriptive_metadata.subject, &Mapper.subject/1)
    genres = Enum.map(work.descriptive_metadata.genre, &Mapper.genre_subject/1)

    (subjects ++ genres)
    |> Enum.reject(&is_nil/1)
    |> Enum.reduce_while({:ok, []}, fn subject, {:ok, refs} ->
      case Client.create_record("/subjects", subject) do
        {:ok, uri} -> {:cont, {:ok, refs ++ [uri]}}
        {:conflict, uri} -> {:cont, {:ok, refs ++ [uri]}}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
  end

  # Creators and contributors become ArchivesSpace agents (person or corporate),
  # deduplicated on authority_id like subjects, and returned as linked_agent
  # entries (creators with no relator, contributors carrying their MARC relator).
  defp ensure_agents(work) do
    (work.descriptive_metadata.creator ++ work.descriptive_metadata.contributor)
    |> Enum.reduce_while({:ok, []}, fn entry, {:ok, agents} ->
      case ensure_agent(entry) do
        {:ok, nil} -> {:cont, {:ok, agents}}
        {:ok, linked_agent} -> {:cont, {:ok, agents ++ [linked_agent]}}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
    |> case do
      {:ok, agents} -> {:ok, Enum.uniq_by(agents, &Map.get(&1, "ref"))}
      other -> other
    end
  end

  defp ensure_agent(entry) do
    case Mapper.agent(entry) do
      nil ->
        {:ok, nil}

      {record, path} ->
        case Client.create_record(path, record) do
          {:ok, uri} -> {:ok, Mapper.linked_agent(uri, entry)}
          {:conflict, uri} -> {:ok, Mapper.linked_agent(uri, entry)}
          {:error, reason} -> {:error, reason}
        end
    end
  end

  defp ensure_digital_object(%{digital_object_uri: nil} = link, work) do
    path = "/repositories/#{link.repository_id}/digital_objects"

    case Client.create_record(path, Mapper.digital_object(work)) do
      {:ok, uri} -> ArchivesSpace.update_link(link, %{digital_object_uri: uri})
      {:conflict, uri} -> ArchivesSpace.update_link(link, %{digital_object_uri: uri})
      {:error, reason} -> {:error, reason}
    end
  end

  defp ensure_digital_object(%{digital_object_uri: uri} = link, work) do
    with {:ok, existing} <- Client.get_record(uri),
         {:ok, _record} <- Client.update_record(uri, Mapper.digital_object(work, existing)) do
      {:ok, link}
    end
  end

  defp delete_digital_object(%{digital_object_uri: nil}), do: :ok
  defp delete_digital_object(%{digital_object_uri: uri}), do: Client.delete_record(uri)

  defp update_archival_object(link, work, subject_refs, linked_agents) do
    with_lock_retry(link.archives_space_uri, fn archival_object ->
      Mapper.apply_work_with_state(archival_object, work,
        subject_refs: subject_refs,
        linked_agents: linked_agents,
        digital_object_uri: link.digital_object_uri,
        sync_state: link.sync_state
      )
    end)
  end

  # GET a record fresh (for its lock_version), build the updated record from it,
  # POST it back, and retry on optimistic-locking conflicts.
  defp with_lock_retry(uri, build_fun, attempt \\ 1) do
    with {:ok, record} <- Client.get_record(uri),
         built <- build_fun.(record) do
      {record, metadata} =
        case built do
          {%{} = record, metadata} -> {record, metadata}
          %{} = record -> {record, nil}
        end

      case Client.update_record(uri, record) do
        {:error, :conflict} when attempt < @lock_conflict_attempts ->
          Logger.warning("Lock conflict updating #{uri} (attempt #{attempt}); retrying")
          with_lock_retry(uri, build_fun, attempt + 1)

        {:error, :conflict} ->
          {:error, "Persistent lock conflict updating #{uri}"}

        {:ok, record} when is_nil(metadata) ->
          {:ok, record}

        {:ok, record} ->
          {:ok, record, metadata}

        other ->
          other
      end
    end
  end

  # Reconciles the work's access file sets to digital_object_components under the
  # managed digital object: each file set becomes a component (label + IIIF image
  # + transcription note), keyed idempotently by component_id == file_set.id.
  defp sync_components(%{digital_object_uri: nil}, _work), do: {:ok, %{"component_uris" => []}}

  defp sync_components(link, work) do
    desired = desired_components(work)

    with {:ok, existing} <- fetch_components(link),
         {:ok, component_uris} <- upsert_components(link, desired, existing),
         :ok <- delete_orphan_components(existing, MapSet.new(desired, & &1.file_set_id)) do
      {:ok, %{"component_uris" => component_uris}}
    end
  end

  defp desired_components(work) do
    work.id
    |> Works.with_file_sets("A")
    |> Map.get(:file_sets)
    |> Enum.with_index()
    |> Enum.map(fn {file_set, index} ->
      %{
        file_set_id: file_set.id,
        position: index,
        label: component_label(file_set),
        image_uri: FileSets.representative_image_url_for(file_set),
        transcription: transcription_content(file_set.id)
      }
    end)
  end

  defp component_label(%{core_metadata: %{label: label}}) when is_binary(label) and label != "",
    do: label

  defp component_label(%{core_metadata: %{original_filename: filename}}), do: filename

  defp transcription_content(file_set_id) do
    file_set_id
    |> FileSets.list_annotations()
    |> Enum.find(&(&1.type == "transcription" and &1.status == "completed"))
    |> case do
      nil -> nil
      annotation -> annotation.content
    end
  end

  # Walks the digital object tree to map existing components by component_id.
  defp fetch_components(link) do
    with {:ok, root} <- Client.get_record(link.digital_object_uri <> "/tree/root"),
         {:ok, uris} <- component_uris(link.digital_object_uri, root) do
      components =
        uris
        |> Enum.flat_map(&fetch_component/1)
        |> Map.new(&{&1["component_id"], &1})

      {:ok, components}
    end
  end

  defp fetch_component(uri) do
    case Client.get_record(uri) do
      {:ok, record} -> [record]
      _ -> []
    end
  end

  defp component_uris(digital_object_uri, %{"waypoints" => count})
       when is_integer(count) and count > 0 do
    Enum.reduce_while(0..(count - 1), {:ok, []}, fn offset, {:ok, acc} ->
      case Client.get(digital_object_uri <> "/tree/waypoint", params: [offset: offset]) do
        {:ok, %{status: 200, body: nodes}} when is_list(nodes) ->
          {:cont, {:ok, acc ++ Enum.map(nodes, &Map.get(&1, "uri"))}}

        {:ok, %{status: status, body: body}} ->
          {:halt, {:error, "ArchivesSpace returned status #{status}: #{inspect(body)}"}}

        {:error, reason} ->
          {:halt, {:error, reason}}
      end
    end)
  end

  defp component_uris(_digital_object_uri, _root), do: {:ok, []}

  defp upsert_components(link, desired, existing) do
    Enum.reduce_while(desired, {:ok, []}, fn component, {:ok, uris} ->
      case upsert_component(link, component, existing) do
        {:ok, uri} -> {:cont, {:ok, uris ++ [uri]}}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
  end

  defp upsert_component(link, component, existing) do
    desired_record = Mapper.digital_object_component(component, link.digital_object_uri)

    case Map.get(existing, component.file_set_id) do
      nil ->
        path = "/repositories/#{link.repository_id}/digital_object_components"

        case Client.create_record(path, desired_record) do
          {:ok, uri} -> {:ok, uri}
          {:conflict, uri} -> {:ok, uri}
          {:error, reason} -> {:error, reason}
        end

      %{"uri" => uri} ->
        case with_lock_retry(uri, &Mapper.apply_component(&1, desired_record)) do
          {:ok, _record} -> {:ok, uri}
          other -> other
        end
    end
  end

  # Only components Meadow created (component_id == a file-set UUID) are ever
  # deleted; archivist-created components are left untouched.
  defp delete_orphan_components(existing, desired_ids) do
    existing
    |> Enum.filter(fn {component_id, _record} ->
      meadow_managed?(component_id) and not MapSet.member?(desired_ids, component_id)
    end)
    |> Enum.reduce_while(:ok, fn {_id, %{"uri" => uri}}, :ok ->
      case Client.delete_record(uri) do
        :ok -> {:cont, :ok}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
  end

  defp meadow_managed?(component_id) when is_binary(component_id),
    do: match?({:ok, _}, Ecto.UUID.cast(component_id))

  defp meadow_managed?(_), do: false
end
