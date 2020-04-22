defmodule Meadow.Data.IndexTimesTest do
  use Meadow.DataCase

  alias Meadow.Data.IndexTimes
  alias Meadow.Data.Schemas.IndexTime

  @valid_attrs %{
    id: Ecto.UUID.generate(),
    indexed_at: DateTime.utc_now()
  }

  setup do
    {:ok, index_time} =
      %IndexTime{}
      |> IndexTime.changeset(@valid_attrs)
      |> Repo.insert()

    {:ok, index_time: index_time}
  end

  test "reset_all!/0" do
    IndexTimes.reset_all!()
    assert Repo.aggregate(IndexTime, :count) == 0
  end
end
