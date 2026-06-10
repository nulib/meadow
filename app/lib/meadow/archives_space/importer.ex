defmodule Meadow.ArchivesSpace.Importer do
  @moduledoc """
  Imports ArchivesSpace resources (finding aids) into Meadow

  `import_resource/2` walks a resource's record tree and:

  1. Creates a Meadow Collection from the resource (title, scope note,
     EAD location as the finding aid URL) and links it, reusing the
     existing collection if the resource is already linked
  2. Creates an unpublished Meadow Work for each archival object at the
     requested levels of description (`file` and `item` by default),
     pulling its title, scope/contents, abstract, and any subjects that
     carry resolvable authority URIs
  3. Links each created work to its archival object, so subsequent
     metadata work in Meadow (batch agent plans, manual edits) syncs back
     to ArchivesSpace via `Meadow.ArchivesSpace.Sync`

  The tree is read through the `tree/root` and `tree/waypoint` endpoints
  rather than `ordered_records`, because the latter silently excludes
  unpublished and suppressed records (and all of their descendants) —
  usually exactly the material that still needs metadata work.

  Archival objects that already have a linked work are skipped, so
  re-importing a resource only picks up records added since the last run.
  Failures on individual archival objects are collected and reported
  without aborting the rest of the import.

  ## Options

  * `:levels` - archival object levels to import (default: `["file", "item"]`)
  * `:work_type` - work type for created works (default: `%{id: "IMAGE", scheme: "work_type"}`)
  * `:accession_prefix` - prefix for generated accession numbers, which
    are built from each archival object's `ref_id` (default: `"aspace:"`)
  * `:ai_ingest` - when `true`, created works are flagged for AI-generated
    metadata, so their ingested digital object images run through the
    `GenerateAIMetadata` pipeline action (default: `false`)

  Whenever an archival object carries digital object images, those images
  are pulled into the Meadow ingest bucket and attached to the work as
  access file sets, which are then sent through the processing pipeline —
  independently of `:ai_ingest`, which only governs AI metadata generation.
  """

  alias Meadow.ArchivesSpace
  alias Meadow.ArchivesSpace.{Client, Digital, Mapper}
  alias Meadow.Data.{Collections, ControlledTerms, FileSets, Works}
  alias Meadow.Pipeline
  alias Meadow.Utils.ChangesetErrors

  require Logger

  @default_levels ~w(file item)
  @default_work_type %{id: "IMAGE", scheme: "work_type"}
  @default_accession_prefix "aspace:"
  @pipeline_context %{context: "ArchivesSpace"}

  @doc """
  Imports an ArchivesSpace resource and its archival objects

  Returns `{:ok, summary}` where summary is a map with the collection,
  a list of created works, a list of skipped archival object URIs
  (already linked or not at a requested level), and any per-record
  errors as `{uri, reason}` tuples.
  """
  def import_resource(resource_uri, opts \\ []) do
    with {:ok, resource} <- Client.get_record(resource_uri),
         {:ok, collection} <- ensure_collection(resource, resource_uri),
         {:ok, summary} <- import_works(resource_uri, collection, opts) do
      {:ok, Map.put(summary, :collection, collection)}
    end
  end

  @doc """
  Like `import_resource/2`, but returns as soon as the collection exists

  The collection is created (or found) synchronously and returned as
  `{:ok, collection}`; the archival object walk and work creation run in
  a supervised background task, with the outcome logged. Built for the
  GraphQL mutation, where walking a large finding aid would exceed the
  request timeout.
  """
  def import_resource_async(resource_uri, opts \\ []) do
    with {:ok, resource} <- Client.get_record(resource_uri),
         {:ok, collection} <- ensure_collection(resource, resource_uri) do
      {:ok, _pid} =
        Task.Supervisor.start_child(Meadow.ArchivesSpace.TaskSupervisor, fn ->
          resource_uri
          |> import_works(collection, opts)
          |> log_import_results(resource_uri)
        end)

      {:ok, collection}
    end
  end

  defp import_works(resource_uri, collection, opts) do
    with {:ok, uris} <- archival_object_uris(resource_uri) do
      levels = Keyword.get(opts, :levels, @default_levels)
      results = Enum.map(uris, &import_archival_object(&1, collection, levels, opts))

      {:ok,
       %{
         created: for({:created, work} <- results, do: work),
         skipped: for({:skipped, uri} <- results, do: uri),
         errors: for({:error, uri, reason} <- results, do: {uri, reason})
       }}
    end
  end

  defp log_import_results({:ok, summary}, resource_uri) do
    Logger.info(
      "ArchivesSpace import of #{resource_uri} complete: " <>
        "#{length(summary.created)} created, #{length(summary.skipped)} skipped, " <>
        "#{length(summary.errors)} errors"
    )

    Enum.each(summary.errors, fn {uri, reason} ->
      Logger.error("ArchivesSpace import error for #{uri}: #{inspect(reason)}")
    end)
  end

  defp log_import_results({:error, reason}, resource_uri) do
    Logger.error("ArchivesSpace import of #{resource_uri} failed: #{inspect(reason)}")
  end

  defp ensure_collection(resource, resource_uri) do
    case ArchivesSpace.get_collection_link_for_uri(resource_uri) do
      nil -> create_collection(resource, resource_uri)
      link -> {:ok, Collections.get_collection!(link.collection_id)}
    end
  end

  defp create_collection(resource, resource_uri) do
    attrs = %{
      title: resource["title"],
      description: resource |> note_contents("scopecontent") |> Enum.join("\n\n"),
      finding_aid_url: resource["ead_location"]
    }

    with {:ok, collection} <- Collections.create_collection(attrs),
         {:ok, _link} <- ArchivesSpace.link_collection(collection, resource_uri) do
      {:ok, collection}
    else
      {:error, changeset} ->
        {:error,
         "Could not create collection: #{inspect(ChangesetErrors.humanize_errors(changeset))}"}
    end
  end

  @doc """
  Returns the URIs of every archival object in a resource, in tree order.

  Walks the resource tree depth-first, paging through each node's waypoints.
  Shared with `Meadow.ArchivesSpace.ImportPreview`, which samples the front
  of this list to build an AI metadata preview.
  """
  def archival_object_uris(resource_uri) do
    with {:ok, root} <- Client.get_record(resource_uri <> "/tree/root") do
      collect_descendants(resource_uri, nil, root)
    end
  end

  defp collect_descendants(resource_uri, parent_uri, %{"waypoints" => waypoint_count})
       when is_integer(waypoint_count) and waypoint_count > 0 do
    Enum.reduce_while(0..(waypoint_count - 1), {:ok, []}, fn offset, {:ok, acc} ->
      with {:ok, nodes} <- fetch_waypoint(resource_uri, parent_uri, offset),
           {:ok, uris} <- collect_nodes(resource_uri, nodes) do
        {:cont, {:ok, acc ++ uris}}
      else
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
  end

  defp collect_descendants(_resource_uri, _parent_uri, _node), do: {:ok, []}

  defp collect_nodes(resource_uri, nodes) do
    Enum.reduce_while(nodes, {:ok, []}, fn %{"uri" => uri} = node, {:ok, acc} ->
      case collect_descendants(resource_uri, uri, node) do
        {:ok, children} -> {:cont, {:ok, acc ++ [uri | children]}}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
  end

  defp fetch_waypoint(resource_uri, parent_uri, offset) do
    params =
      case parent_uri do
        nil -> [offset: offset]
        parent -> [offset: offset, parent_node: parent]
      end

    case Client.get(resource_uri <> "/tree/waypoint", params: params) do
      {:ok, %{status: 200, body: nodes}} when is_list(nodes) ->
        {:ok, nodes}

      {:ok, %{status: status, body: body}} ->
        {:error, "ArchivesSpace returned status #{status}: #{inspect(body)}"}

      {:error, error} ->
        {:error, error}
    end
  end

  defp import_archival_object(uri, collection, levels, opts) do
    if ArchivesSpace.work_linked_to_uri?(uri) do
      {:skipped, uri}
    else
      case Client.get_record(uri) do
        {:ok, archival_object} ->
          if Map.get(archival_object, "level") in levels do
            create_work_from_archival_object(archival_object, collection, opts)
          else
            {:skipped, uri}
          end

        {:error, reason} ->
          {:error, uri, reason}
      end
    end
  rescue
    error -> {:error, uri, Exception.message(error)}
  end

  defp create_work_from_archival_object(%{"uri" => uri} = archival_object, collection, opts) do
    attrs = work_attrs(archival_object, collection, opts)

    {file_sets, representative_accession} =
      Digital.ingest_file_sets(archival_object, attrs.accession_number)

    attrs = Map.put(attrs, :file_sets, file_sets)

    with {:ok, work} <- Works.create_work(attrs),
         {:ok, _link} <-
           ArchivesSpace.link_work(work, uri, %{ref_id: archival_object["ref_id"]}) do
      Logger.info("Imported #{uri} as work #{work.id} with #{length(file_sets)} file set(s)")
      set_representative_image(work, representative_accession)
      kickoff_file_sets(work)
      {:created, work}
    else
      {:error, %Ecto.Changeset{} = changeset} ->
        {:error, uri, inspect(ChangesetErrors.humanize_errors(changeset))}

      {:error, reason} ->
        {:error, uri, reason}
    end
  end

  defp work_attrs(archival_object, collection, opts) do
    prefix = Keyword.get(opts, :accession_prefix, @default_accession_prefix)

    %{
      accession_number: prefix <> accession_id(archival_object),
      ai_ingest: Keyword.get(opts, :ai_ingest, false),
      work_type: Keyword.get(opts, :work_type, @default_work_type),
      published: false,
      visibility: %{id: "RESTRICTED", scheme: "visibility"},
      collection_id: collection.id,
      descriptive_metadata: %{
        title: archival_object["display_string"] || archival_object["title"],
        description: note_contents(archival_object, "scopecontent"),
        abstract: note_contents(archival_object, "abstract"),
        subject: subjects(archival_object)
      }
    }
  end

  # Honors ArchivesSpace's is_representative flags by pointing the work at the
  # file set Digital picked out, the same way a CSV ingest honors its
  # `work image` column. When nothing is flagged the default Meadow chose at
  # creation stands.
  defp set_representative_image(_work, nil), do: :ok

  defp set_representative_image(work, accession_number) do
    file_set = FileSets.get_file_set_by_accession_number!(accession_number)
    Works.set_representative_image!(work, file_set)
    :ok
  end

  # Sends each ingested digital object image through the processing pipeline.
  # The pipeline start is overridable (via application env) so tests don't
  # block on the digest-tag lambda writing checksum tags.
  defp kickoff_file_sets(%{file_sets: file_sets}) when is_list(file_sets),
    do: Enum.each(file_sets, &start_pipeline/1)

  defp kickoff_file_sets(_work), do: :ok

  defp start_pipeline(file_set) do
    case Application.get_env(:meadow, :archives_space_pipeline_starter) do
      nil -> Pipeline.ingest_uploaded_file_set(file_set, @pipeline_context)
      fun when is_function(fun, 1) -> fun.(file_set)
    end
  end

  defp accession_id(%{"ref_id" => ref_id}) when is_binary(ref_id), do: ref_id
  defp accession_id(%{"uri" => uri}), do: uri |> String.split("/") |> List.last()

  # Notes Meadow wrote during a previous sync are excluded so a re-import
  # doesn't round-trip them back into the work.
  defp note_contents(record, type) do
    record
    |> Map.get("notes", [])
    |> Enum.filter(&(Map.get(&1, "type") == type and Map.get(&1, "label") != Mapper.note_label()))
    |> Enum.flat_map(fn
      %{"subnotes" => subnotes} -> Enum.map(subnotes, &Map.get(&1, "content"))
      %{"content" => content} when is_list(content) -> content
      %{"content" => content} -> [content]
      _ -> []
    end)
    |> Enum.reject(&is_nil/1)
  end

  defp subjects(archival_object) do
    archival_object
    |> Map.get("subjects", [])
    |> Enum.map(&fetch_subject(Map.get(&1, "ref")))
    |> Enum.reject(&is_nil/1)
  end

  defp fetch_subject(nil), do: nil

  defp fetch_subject(subject_uri) do
    with {:ok, %{"authority_id" => authority_id} = subject} when is_binary(authority_id) <-
           Client.get_record(subject_uri),
         {{:ok, _}, _term} <- ControlledTerms.fetch(authority_id) do
      %{
        role: %{id: subject_role(subject), scheme: "subject_role"},
        term: %{id: authority_id}
      }
    else
      _ ->
        Logger.warning(
          "Skipping ArchivesSpace subject #{subject_uri}: no resolvable authority_id"
        )

        nil
    end
  end

  defp subject_role(%{"terms" => [%{"term_type" => "geographic"} | _]}), do: "GEOGRAPHICAL"
  defp subject_role(%{"terms" => [%{"term_type" => "temporal"} | _]}), do: "TEMPORAL"
  defp subject_role(_), do: "TOPICAL"
end
