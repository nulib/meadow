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
  end
end
