defmodule Meadow.Data.WorksTest do
  use Meadow.DataCase

  alias Meadow.Data.Schemas.Work
  alias Meadow.Data.Works

  describe "queries" do
    @valid_attrs %{
      accession_number: "12345",
      visibility: "open",
      work_type: "image",
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

    test "update_work/2 updates a work" do
      work = work_fixture()
      assert {:ok, %Work{} = work} = Works.update_work(work, %{metadata: %{title: "New name"}})
      assert work.metadata.title == "New name"
    end

    test "update_work/2 with invalid attributes returns an error" do
      work = work_fixture()
      assert {:error, %Ecto.Changeset{}} = Works.update_work(work, %{work_type: "Dictionary"})
    end

    test "delete_work/1 deletes a work" do
      work = work_fixture()
      assert {:ok, %Work{} = work} = Works.delete_work(work)
      assert Enum.empty?(Works.list_works())
    end

    test "get_work!/1 returns a work by id" do
      work = work_fixture()
      assert %Work{} = Works.get_work!(work.id)
    end

    test "accession_exists?/1 returns true if accession is already taken" do
      work = work_fixture()

      assert Works.accession_exists?(work.accession_number) == true
    end
  end
end
