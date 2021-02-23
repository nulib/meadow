defmodule Meadow.Data.IndexTimesTest do
  use Meadow.DataCase

  alias Meadow.Data.IndexTimes
  alias Meadow.Data.Schemas.IndexTime

  setup tags do
    with count <- Map.get(tags, :count, 1) do
      index_time_ids =
        1..count
        |> Enum.map(fn _ ->
          with {:ok, index_time} <-
                 %IndexTime{}
                 |> IndexTime.changeset(%{
                   id: Ecto.UUID.generate(),
                   indexed_at: DateTime.utc_now()
                 })
                 |> Repo.insert() do
            index_time.id
          end
        end)

      {:ok, index_time_ids: index_time_ids}
    end
  end

  @tag count: 50
  test "change/2", %{index_time_ids: index_time_ids} do
    [update | [delete | _]] = index_time_ids |> Enum.chunk_every(40)
    add = Enum.map(1..20, fn _ -> Ecto.UUID.generate() end)
    assert {added, updated, deleted} = IndexTimes.change(add ++ update, delete)
    assert length(added) == 20
    assert length(updated) == 40
    assert length(deleted) == 10
    assert Repo.aggregate(IndexTime, :count) == 60
  end

  @tag count: 30
  test "touch/1", %{index_time_ids: update} do
    add = Enum.map(1..20, fn _ -> Ecto.UUID.generate() end)
    assert {added, updated} = IndexTimes.touch(add ++ update)
    assert length(added) == 20
    assert length(updated) == 30
    assert Repo.aggregate(IndexTime, :count) == 50
  end

  @tag count: 25
  test "delete/1", %{index_time_ids: index_time_ids} do
    delete = index_time_ids |> Enum.take(10)
    assert IndexTimes.delete(delete) |> length() == 10
    assert Repo.aggregate(IndexTime, :count) == 15
  end

  @tag count: 25
  test "reset_all!/0" do
    assert IndexTimes.reset_all!() == {25, nil}
    assert Repo.aggregate(IndexTime, :count) == 0
  end
end
