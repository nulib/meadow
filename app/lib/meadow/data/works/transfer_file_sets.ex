defmodule Meadow.Data.Works.TransferFileSets do
  @moduledoc """
  Transfer file sets from one work to another.
  """

  import Ecto.Query, warn: false
  alias Ecto.Multi
  alias Meadow.Data
  alias Meadow.Data.IndexBatcher
  alias Meadow.Data.Schemas.FileSet
  alias Meadow.Data.Works
  alias Meadow.Repo
  alias Meadow.Utils.ChangesetErrors

  require Logger

  @doc """
  Transfer a subset of file sets to an existing work or create a new work.

  ## Parameters
  - `fileset_ids`: List of file set IDs to transfer
  - `create_work`: Boolean - whether to create a new work or transfer to existing
  - `work_attributes`: Map containing all work-related information
  - `delete_empty_works`: Boolean - whether to delete source works that become empty (default: true)

  ### For creating new work (create_work: true):
  The `work_attributes` map should contain:
  - **Required**: `accession_number`, `work_type`
  - **Optional work fields**: `collection_id`, `published`, `visibility`, `behavior`, `ingest_sheet_id`
  - **Descriptive metadata**: Pass any descriptive metadata fields in a `descriptive_metadata` map
  - **Administrative metadata**: Pass any administrative metadata fields in an `administrative_metadata` map

  ### For transferring to existing work (create_work: false):
  The `work_attributes` map should contain:
  - **Required**: `accession_number` (for lookup)

  ## Examples

      # Simple transfer to existing work (delete_empty_works defaults to true)
      iex> TransferFileSets.transfer_subset(%{
      ...>   fileset_ids: ["id1", "id2"],
      ...>   create_work: false,
      ...>   accession_number: "acc123"
      ...> })
      {:ok, %{transferred_fileset_ids: ["id1", "id2"]}}

      # Transfer to existing work without deleting empty source works
      iex> TransferFileSets.transfer_subset(%{
      ...>   fileset_ids: ["id1", "id2"],
      ...>   create_work: false,
      ...>   accession_number: "acc123",
      ...>   delete_empty_works: false
      ...> })
      {:ok, %{transferred_fileset_ids: ["id1", "id2"]}}

      # Create new work with comprehensive metadata
      iex> TransferFileSets.transfer_subset(%{
      ...>   fileset_ids: ["id1", "id2"],
      ...>   create_work: true,
      ...>   work_attributes: %{
      ...>     accession_number: "work_1",
      ...>     work_type: "IMAGE",
      ...>     collection_id: "coll-uuid",
      ...>     published: false,
      ...>     visibility: %{id: "RESTRICTED", scheme: "visibility"},
      ...>     descriptive_metadata: %{
      ...>       title: "Sample Work Title",
      ...>       description: ["Work description"],
      ...>       abstract: ["Work abstract"],
      ...>       alternate_title: ["Work's alternate title"],
      ...>       keywords: ["keyword1", "keyword2"],
      ...>       identifier: ["work_identifier"],
      ...>       catalog_key: ["work_cd"],
      ...>       box_name: ["Box name"],
      ...>       box_number: ["Box number"],
      ...>       folder_name: ["Folder name"],
      ...>       folder_number: ["Folder number"],
      ...>       series: ["Series name"],
      ...>       physical_description_material: ["Material description"],
      ...>       physical_description_size: ["Size description"],
      ...>       publisher: ["Publisher name"],
      ...>       rights_holder: ["Rights holder"],
      ...>       terms_of_use: "Terms of use statement",
      ...>       license: %{id: "http://creativecommons.org/publicdomain/mark/1.0/", scheme: "license"},
      ...>       rights_statement: %{id: "http://rightsstatements.org/vocab/NKC/1.0/", scheme: "rights_statement"},
      ...>       date_created: [%{edtf: "2025", humanized: "2025"}]
      ...>     },
      ...>     administrative_metadata: %{
      ...>       project_name: ["Project name"],
      ...>       project_manager: ["Project manager"],
      ...>       project_desc: ["Project description"],
      ...>       project_proposer: ["Project proposer"],
      ...>       project_task_number: ["Task number"],
      ...>       project_cycle: "Project cycle",
      ...>       library_unit: %{id: "MUSIC_LIBRARY", scheme: "library_unit"},
      ...>       preservation_level: %{id: "1", scheme: "preservation_level"},
      ...>       status: %{id: "IN PROGRESS", scheme: "status"}
      ...>     }
      ...>   }
      ...> })
      {:ok, %{transferred_fileset_ids: ["id1", "id2"], created_work_id: "work_uuid"}}

      # Error case
      iex> TransferFileSets.transfer_subset(%{
      ...>   fileset_ids: [],
      ...>   create_work: false,
      ...>   accession_number: "acc123"
      ...> })
      {:error, "Fileset IDs cannot be empty"}
  """
  @spec transfer_subset(map()) :: {:ok, map()} | {:error, String.t()}
  def transfer_subset(%{create_work: true, work_attributes: work_attributes} = args) do
    %{fileset_ids: fileset_ids} = args
    delete_empty_works = Map.get(args, :delete_empty_works, true)

    multi =
      Multi.new()
      |> Multi.run(:validate_fileset_ids, fn _repo, _changes ->
        validate_fileset_ids(fileset_ids)
      end)
      |> Multi.run(:validate_work_attributes, fn _repo, _changes ->
        validate_work_attributes(work_attributes)
      end)
      |> Multi.run(:create_target_work, fn _repo, _changes ->
        create_target_work(work_attributes)
      end)
      |> Multi.run(:get_source_work_ids, fn _repo, _changes ->
        get_source_work_ids_from_filesets(fileset_ids)
      end)
      |> Multi.run(:transfer_filesets, fn _repo, %{create_target_work: target_work_id} ->
        transfer_fileset_subset(fileset_ids, target_work_id)
      end)
      |> maybe_add_delete_empty_works_step(delete_empty_works)

    case Repo.transaction(multi, timeout: :infinity) do
      {:ok,
       %{
         create_target_work: target_work_id,
         transfer_filesets: transferred_ids,
         get_source_work_ids: source_work_ids
       } = results} ->
        # Only reindex source works after successful transaction
        deleted_work_ids = Map.get(results, :delete_empty_works, [])
        reindex_source_works_after_transaction(source_work_ids, deleted_work_ids)

        {:ok,
         %{
           transferred_fileset_ids: transferred_ids,
           created_work_id: target_work_id
         }}

      {:error, failed_operation, failed_value, _changes_so_far} ->
        error_message = humanize_subset_error(failed_operation, failed_value)
        {:error, error_message}
    end
  end

  def transfer_subset(%{create_work: false, accession_number: accession_number} = args)
      when is_binary(accession_number) and accession_number != "" do
    %{fileset_ids: fileset_ids} = args
    delete_empty_works = Map.get(args, :delete_empty_works, true)

    multi =
      Multi.new()
      |> Multi.run(:validate_fileset_ids, fn _repo, _changes ->
        validate_fileset_ids(fileset_ids)
      end)
      |> Multi.run(:get_target_work, fn _repo, _changes ->
        get_target_work(accession_number)
      end)
      |> Multi.run(:get_source_work_ids, fn _repo, _changes ->
        get_source_work_ids_from_filesets(fileset_ids)
      end)
      |> Multi.run(:transfer_filesets, fn _repo, %{get_target_work: target_work_id} ->
        transfer_fileset_subset(fileset_ids, target_work_id)
      end)
      |> maybe_add_delete_empty_works_step(delete_empty_works)

    case Repo.transaction(multi, timeout: :infinity) do
      {:ok, %{transfer_filesets: transferred_ids, get_source_work_ids: source_work_ids} = results} ->
        # Only reindex source works after successful transaction
        deleted_work_ids = Map.get(results, :delete_empty_works, [])
        reindex_source_works_after_transaction(source_work_ids, deleted_work_ids)

        {:ok,
         %{
           transferred_fileset_ids: transferred_ids
         }}

      {:error, failed_operation, failed_value, _changes_so_far} ->
        error_message = humanize_subset_error(failed_operation, failed_value)
        {:error, error_message}
    end
  end

  def transfer_subset(%{create_work: false} = _args) do
    {:error, "Accession number is required when transferring to existing work"}
  end

  def transfer_subset(%{create_work: true} = _args) do
    {:error, "Work attributes are required when creating a new work"}
  end

  @doc """
  Transfer file sets from one work to another.

  ## Examples

      iex> TransferFileSets.transfer(from_work_id, to_work_id)
      {:ok, to_work_id}

      iex> TransferFileSets.transfer(from_work_id, to_work_id)
      {:error, [failed_operation: :fetch_work, failed_value: :work_not_found]}
  """
  @spec transfer(Ecto.UUID.t(), Ecto.UUID.t()) ::
          {:ok, Ecto.UUID.t()} | {:error, any()}
  def transfer(from_work_id, to_work_id) do
    multi =
      Multi.new()
      |> Multi.run(:from_work, fn _repo, _changes -> fetch_work(from_work_id) end)
      |> Multi.run(:to_work, fn _repo, _changes -> fetch_work(to_work_id) end)
      |> Multi.run(:check_work_types, fn _repo, %{from_work: from_work, to_work: to_work} ->
        check_work_types(from_work, to_work)
      end)
      |> Multi.run(:transfer_file_sets, fn _repo, _changes ->
        transfer_file_sets(from_work_id, to_work_id)
      end)
      |> Multi.run(:delete_empty_work, fn _repo, _changes -> delete_empty_work(from_work_id) end)
      |> Multi.run(:refetch_to_work, fn _repo, _changes -> fetch_work(to_work_id) end)

    case Repo.transaction(multi, timeout: :infinity) do
      {:ok, %{refetch_to_work: work, delete_empty_work: delete_result}} ->
        # Only reindex source work after successful transaction
        reindex_source_work_if_not_deleted(from_work_id, delete_result)
        {:ok, work}

      {:error, failed_operation, failed_value, _changes_so_far} ->
        error_message = humanize_error(failed_operation, failed_value)
        {:error, error_message}
    end
  end

  defp validate_fileset_ids([]), do: {:error, "Fileset IDs cannot be empty"}

  defp validate_fileset_ids(fileset_ids) when is_list(fileset_ids) do
    if Enum.all?(fileset_ids, &is_binary/1) and Enum.all?(fileset_ids, &(&1 != "")) do
      {:ok, :valid}
    else
      {:error, "All fileset IDs must be non-empty strings"}
    end
  end

  defp validate_fileset_ids(_), do: {:error, "Fileset IDs must be a list"}

  defp validate_work_attributes(%{accession_number: accession, work_type: work_type})
       when is_binary(accession) and accession != "" and is_binary(work_type) and work_type != "" do
    {:ok, :valid}
  end

  defp validate_work_attributes(%{accession_number: _}) do
    {:error, "work_type is required when creating a new work"}
  end

  defp validate_work_attributes(%{work_type: _}) do
    {:error, "accession_number is required when creating a new work"}
  end

  defp validate_work_attributes(_) do
    {:error, "accession_number and work_type are required when creating a new work"}
  end

  defp create_target_work(%{accession_number: accession, work_type: work_type} = work_attributes) do
    # Build descriptive metadata from provided arguments
    descriptive_metadata = build_descriptive_metadata(work_attributes)

    # Build administrative metadata from provided arguments
    administrative_metadata = build_administrative_metadata(work_attributes)

    # Build the work attributes with all possible fields
    work_attrs =
      %{
        accession_number: accession,
        work_type: %{id: work_type, scheme: "work_type"},
        descriptive_metadata: descriptive_metadata,
        administrative_metadata: administrative_metadata,
        visibility:
          Map.get(work_attributes, :visibility, %{id: "RESTRICTED", scheme: "visibility"}),
        published: Map.get(work_attributes, :published, false)
      }
      |> maybe_add_collection_id(work_attributes)
      |> maybe_add_behavior(work_attributes)
      |> maybe_add_ingest_sheet_id(work_attributes)

    case Works.create_work(work_attrs) do
      {:ok, work} ->
        {:ok, work.id}

      {:error, changeset} ->
        errors = ChangesetErrors.humanize_errors(changeset)
        {:error, "Failed to create new work: #{inspect(errors)}"}
    end
  end

  defp build_descriptive_metadata(work_attributes) do
    descriptive_metadata = Map.get(work_attributes, :descriptive_metadata, %{})

    # Handle legacy work_title parameter for backwards compatibility
    case Map.get(work_attributes, :work_title) do
      nil -> descriptive_metadata
      title -> Map.put(descriptive_metadata, :title, title)
    end
  end

  defp build_administrative_metadata(work_attributes) do
    Map.get(work_attributes, :administrative_metadata, %{})
  end

  defp maybe_add_collection_id(attrs, %{collection_id: collection_id}) do
    Map.put(attrs, :collection_id, collection_id)
  end

  defp maybe_add_collection_id(attrs, _), do: attrs

  defp maybe_add_behavior(attrs, %{behavior: behavior}) do
    Map.put(attrs, :behavior, behavior)
  end

  defp maybe_add_behavior(attrs, _), do: attrs

  defp maybe_add_ingest_sheet_id(attrs, %{ingest_sheet_id: ingest_sheet_id}) do
    Map.put(attrs, :ingest_sheet_id, ingest_sheet_id)
  end

  defp maybe_add_ingest_sheet_id(attrs, _), do: attrs

  defp get_target_work(accession_number) do
    work = Works.get_work_by_accession_number!(accession_number)
    {:ok, work.id}
  rescue
    Ecto.NoResultsError -> {:error, "No work found with accession #{accession_number}"}
  end

  defp transfer_fileset_subset(fileset_ids, target_work_id) do
    max_rank_in_target_work =
      FileSet
      |> where(work_id: ^target_work_id)
      |> select([fs], max(fs.rank))
      |> Repo.one() || 0

    # Get the filesets and validate they exist
    filesets =
      FileSet
      |> where([fs], fs.id in ^fileset_ids)
      |> Repo.all()

    with {:ok, :valid} <- validate_filesets_exist(filesets, fileset_ids),
         {:ok, transferred_ids} <-
           perform_fileset_transfer(filesets, target_work_id, max_rank_in_target_work) do
      Logger.info("Transferred #{length(transferred_ids)} file sets to work #{target_work_id}")
      {:ok, transferred_ids}
    end
  end

  defp validate_filesets_exist(filesets, fileset_ids) do
    found_ids = Enum.map(filesets, & &1.id)
    missing_ids = fileset_ids -- found_ids

    if length(missing_ids) > 0 do
      {:error, "Filesets not found: #{Enum.join(missing_ids, ", ")}"}
    else
      {:ok, :valid}
    end
  end

  defp perform_fileset_transfer(filesets, target_work_id, max_rank_in_target_work) do
    updates =
      filesets
      |> Enum.with_index(max_rank_in_target_work + 1)
      |> Enum.map(fn {file_set, new_rank} ->
        changeset = FileSet.changeset(file_set, %{work_id: target_work_id, rank: new_rank})

        case Repo.update(changeset) do
          {:ok, _} -> {:ok, file_set.id}
          {:error, _} -> {:error, file_set.id}
        end
      end)

    failed_updates = Enum.filter(updates, fn {status, _} -> status == :error end)

    if length(failed_updates) > 0 do
      failed_ids = Enum.map(failed_updates, fn {_, id} -> id end)
      {:error, "Failed to transfer filesets: #{Enum.join(failed_ids, ", ")}"}
    else
      transferred_ids = Enum.map(updates, fn {:ok, id} -> id end)
      {:ok, transferred_ids}
    end
  end

  defp maybe_add_delete_empty_works_step(multi, true) do
    multi
    |> Multi.run(:delete_empty_works, fn _repo, %{get_source_work_ids: source_work_ids} ->
      delete_empty_works(source_work_ids)
    end)
  end

  defp maybe_add_delete_empty_works_step(multi, false), do: multi

  defp get_source_work_ids_from_filesets(fileset_ids) do
    source_work_ids =
      FileSet
      |> where([fs], fs.id in ^fileset_ids)
      |> select([fs], fs.work_id)
      |> distinct(true)
      |> Repo.all()

    {:ok, source_work_ids}
  end

  defp reindex_source_works_after_transaction(source_work_ids, deleted_work_ids) do
    # Remove any nil work IDs and any works that were deleted
    valid_work_ids =
      Enum.reject(source_work_ids, fn work_id ->
        is_nil(work_id) || work_id in deleted_work_ids
      end)

    if length(valid_work_ids) > 0 do
      IndexBatcher.reindex(valid_work_ids, :works)
      Logger.info("Reindexed #{length(valid_work_ids)} source works after fileset transfer")
    end
  end

  defp reindex_source_work_if_not_deleted(_work_id, :deleted) do
    # Work was deleted, no need to reindex
    :ok
  end

  defp reindex_source_work_if_not_deleted(work_id, _) do
    # Work still exists, reindex it to reflect removed filesets
    IndexBatcher.reindex([work_id], :works)
    Logger.info("Reindexed source work #{work_id} after fileset transfer")
    :ok
  end

  defp delete_empty_works(source_work_ids) do
    # For each source work, check if it became empty after the transfer
    results = Enum.map(source_work_ids, &maybe_delete_empty_work/1)

    case Enum.filter(results, &match?({:error, _}, &1)) do
      [] ->
        deleted_works =
          results
          |> Enum.filter(fn {_, result} -> is_binary(result) end)
          |> Enum.map(fn {_, work_id} -> work_id end)

        {:ok, deleted_works}

      failed_deletions ->
        failed_work_ids = Enum.map(failed_deletions, fn {_, work_id} -> work_id end)
        {:error, "Failed to delete empty works: #{Enum.join(failed_work_ids, ", ")}"}
    end
  end

  defp maybe_delete_empty_work(work_id) do
    current_fileset_count =
      FileSet
      |> where([fs], fs.work_id == ^work_id)
      |> Repo.aggregate(:count, :id)

    case current_fileset_count do
      0 -> delete_work_if_exists(work_id)
      _ -> {:ok, :not_empty}
    end
  end

  defp delete_work_if_exists(work_id) do
    case Works.get_work(work_id) do
      nil -> {:ok, :already_deleted}
      work -> delete_work_safely(work, work_id)
    end
  end

  defp delete_work_safely(work, work_id) do
    # Clear representative_file_set_id before deletion to avoid constraint issues
    work =
      work
      |> Ecto.Changeset.change(%{representative_file_set_id: nil})
      |> Repo.update!()

    case Repo.delete(work) do
      {:ok, _} ->
        Logger.info("Deleted empty work #{work_id}")
        {:ok, work_id}

      {:error, _} ->
        {:error, work_id}
    end
  end

  defp humanize_subset_error(failed_operation, failed_value) do
    case failed_operation do
      :validate_fileset_ids -> failed_value
      :validate_work_attributes -> failed_value
      :create_target_work -> failed_value
      :get_target_work -> failed_value
      :transfer_filesets -> failed_value
      :get_source_work_ids -> failed_value
      :delete_empty_works -> failed_value
      _ -> "Unknown error occurred"
    end
  end

  defp fetch_work(work_id) do
    case Works.get_work(work_id) do
      nil -> {:error, :work_not_found}
      work -> {:ok, work}
    end
  rescue
    Ecto.Query.CastError -> {:error, :work_not_found}
  end

  defp check_work_types(%{work_type: %{id: from_type}}, %{work_type: %{id: to_type}}) do
    if from_type == to_type do
      {:ok, :work_type_match}
    else
      {:error, :work_type_mismatch}
    end
  end

  defp transfer_file_sets(from_work_id, to_work_id) do
    max_rank_in_target_work =
      FileSet
      |> where(work_id: ^to_work_id)
      |> select([fs], max(fs.rank))
      |> Repo.one() || 0

    file_sets = Data.ranked_file_sets_for_work(from_work_id)

    updates =
      file_sets
      |> Enum.with_index(max_rank_in_target_work + 1)
      |> Enum.map(fn {file_set, new_rank} ->
        changeset = FileSet.changeset(file_set, %{work_id: to_work_id, rank: new_rank})

        case Repo.update(changeset) do
          {:ok, _} -> {:ok, :transferred}
          {:error, _} -> {:error, :transfer_failed}
        end
      end)

    if Enum.all?(updates, fn {:ok, _} -> true end) do
      Logger.info(
        "Transferred #{Enum.count(updates)} file sets from #{from_work_id} to #{to_work_id}"
      )

      {:ok, :transferred}
    else
      {:error, :transfer_failed}
    end
  end

  defp delete_empty_work(work_id) do
    work = Works.with_file_sets(work_id)

    if Enum.empty?(work.file_sets) do
      case Repo.delete(work) do
        {:ok, _} ->
          Logger.info("Deleted empty work #{work_id}")
          {:ok, :deleted}

        _ ->
          {:error, :delete_failed}
      end
    else
      {:ok, :work_not_empty}
    end
  end

  defp humanize_error(failed_operation, failed_value) do
    "#{describe_operation(failed_operation)}: #{describe_error(failed_value)}"
  end

  defp describe_operation(operation) do
    case operation do
      :from_work -> "Fetching 'from' work"
      :to_work -> "Fetching 'to' work"
      :check_work_types -> "Checking work types"
      :transfer_file_sets -> "Transferring file sets"
      :delete_empty_work -> "Deleting empty work"
      :refetch_to_work -> "Refetching work"
      _ -> "Unknown operation"
    end
  end

  defp describe_error(error) do
    case error do
      :work_not_found -> "work not found (no changes were made)"
      :work_type_mismatch -> "work types do not match (no changes were made)"
      :transfer_failed -> "file sets transfer failed (no changes were made)"
      :delete_failed -> "deletion failed (no changes were made)"
      _ -> "unknown error (no changes were made)"
    end
  end
end
