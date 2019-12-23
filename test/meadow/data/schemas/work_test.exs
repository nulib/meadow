defmodule Meadow.Data.Schemas.WorkTest do
  use Meadow.DataCase

  alias Meadow.Data.Schemas.Work

  describe "works" do
    @valid_attrs %{
      accession_number: "12345",
      visibility: "open",
      work_type: "image",
      metadata: %{title: "Test"}
    }

    test "created work has a ULID identifier" do
      {:ok, work} =
        %Work{}
        |> Work.changeset(@valid_attrs)
        |> Repo.insert()

      assert {:ok, <<data::binary-size(16)>>} = Ecto.ULID.dump(work.id)
    end
  end
end
