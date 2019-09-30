defmodule Meadow.Data.WorksTest do
  use Meadow.DataCase

  alias Meadow.Data.Works
  alias Meadow.Data.Works.Work

  describe "queries" do
    @valid_attrs %{
      accession_number: "12345",
      visibility: "open",
      work_type: "Image",
      metadata: %{title: "Test"}
    }
    @invalid_attrs %{accession_number: nil}

    test "list_works/0 returns all works" do
      work_fixture()
      assert length(Works.list_works()) == 1
    end

    test "get_works_by_title/1 fetches the works by title" do
      work = work_fixture()
      title = work.metadata.title
      assert length(Works.get_works_by_title(title)) == 1
    end

    test "create_work/1 with valid data creates a work" do
      assert {:ok, %Work{} = work} = Works.create_work(@valid_attrs)
    end

    test "create_work/1 with invalid data does not create a work" do
      assert {:error, %Ecto.Changeset{}} = Works.create_work(@invalid_attrs)
    end
  end
end
