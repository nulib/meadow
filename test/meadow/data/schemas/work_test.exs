defmodule Meadow.Data.Schemas.WorkTest do
  use Meadow.DataCase

  alias Meadow.Data.Schemas.Work

  describe "works" do
    @valid_attrs %{
      accession_number: "12345",
      descriptive_metadata: %{title: "Test"}
    }

    test "created work has a UUID identifier" do
      {:ok, work} =
        %Work{}
        |> Work.changeset(@valid_attrs)
        |> Repo.insert()

      assert {:ok, <<data::binary-size(16)>>} = Ecto.UUID.dump(work.id)
    end
  end
end
