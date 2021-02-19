defmodule Meadow.Data.Schemas.IndexTimeTest do
  @moduledoc false
  use Meadow.DataCase

  alias Meadow.Data.Schemas.IndexTime

  describe "index_times" do
    @valid_attrs %{
      id: Ecto.UUID.generate(),
      indexed_at: DateTime.utc_now()
    }

    test "id and indexed_at are required" do
      assert {:error, %Ecto.Changeset{}} =
               %IndexTime{}
               |> IndexTime.changeset(%{})
               |> Repo.insert()
    end

    test "created index_time has a UUID identifier" do
      {:ok, index_time} =
        %IndexTime{}
        |> IndexTime.changeset(@valid_attrs)
        |> Repo.insert()

      assert {:ok, <<_data::binary-size(16)>>} = Ecto.UUID.dump(index_time.id)
    end
  end
end
