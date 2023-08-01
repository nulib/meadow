defmodule Meadow.Data.Works.TransferFileSets do
  @moduledoc """
  Transfer file sets from one work to another.
  """

  import Ecto.Query, warn: false
  alias Ecto.Multi
  alias Meadow.Data
  alias Meadow.Data.Schemas.FileSet
  alias Meadow.Data.Works
  alias Meadow.Repo

  require Logger

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

    case Repo.transaction(multi) do
      {:ok, %{refetch_to_work: work}} ->
        {:ok, work}

      {:error, failed_operation, failed_value, _changes_so_far} ->
        error_message = humanize_error(failed_operation, failed_value)
        {:error, error_message}
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
      {:error, :work_not_found}
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
