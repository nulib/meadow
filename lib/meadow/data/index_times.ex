defmodule Meadow.Data.IndexTimes do
  @moduledoc """
  The IndexTimes context.
  """

  alias Meadow.Data.Schemas.IndexTime
  alias Meadow.Repo

  import Ecto.Query

  require Logger

  def change(index_ids, delete_ids) do
    with {add_ids, update_ids} <- touch(index_ids) do
      delete(delete_ids)
      {add_ids, update_ids, delete_ids}
    end
  end

  def delete(ids) do
    with {_count, deleted_ids} <-
           from(t in IndexTime, where: t.id in ^ids, select: t.id)
           |> Repo.delete_all() do
      deleted_ids
    end
  end

  def reset_all! do
    Repo.delete_all(IndexTime)
  end

  def touch(ids, timestamp \\ DateTime.utc_now()) do
    with ids <- Enum.uniq(ids) do
      result =
        Repo.transaction(fn ->
          {_count, update_ids} =
            from(t in IndexTime, where: t.id in ^ids, select: t.id)
            |> Repo.update_all(set: [indexed_at: timestamp])

          with add_ids <- ids -- update_ids,
               changesets <- add_ids |> Enum.map(&%{id: &1, indexed_at: timestamp}) do
            Repo.insert_all(IndexTime, changesets,
              on_conflict: :nothing,
              conflict_target: [:id]
            )

            {add_ids, update_ids}
          end
        end)

      case result do
        {:ok, counts} -> counts
        other -> other
      end
    end
  end
end
