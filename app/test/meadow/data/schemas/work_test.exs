defmodule Meadow.Data.Schemas.WorkTest do
  use Meadow.AuthorityCase
  use Meadow.DataCase

  alias Meadow.Data.Schemas.Work

  describe "works" do
    setup do
      {:ok,
       %{
         attrs: %{
           accession_number: "12345",
           descriptive_metadata: %{title: "Test"}
         }
       }}
    end

    test "created work has a UUID identifier", %{attrs: attrs} do
      {:ok, work} =
        %Work{}
        |> Work.changeset(attrs)
        |> Repo.insert()

      assert {:ok, <<_data::binary-size(16)>>} = Ecto.UUID.dump(work.id)
    end

    test "accession number cannot have leading or trailing spaces", %{attrs: attrs} do
      invalid_attrs = Map.put(attrs, :accession_number, " 12345 ")

      assert changeset = Work.changeset(%Work{}, invalid_attrs)
      assert changeset.errors[:accession_number] ==
        {"cannot have leading or trailing spaces", []}
    end
  end
end
