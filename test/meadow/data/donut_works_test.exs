defmodule Meadow.Data.DonutWorksTest do
  use Meadow.DataCase

  alias Meadow.Data.DonutWorks
  alias Meadow.Data.Schemas.DonutWork

  describe "queries" do
    @valid_attrs %{
      work_id: Ecto.UUID.bingenerate()
    }

    @invalid_attrs %{work_id: "blah"}

    test "create_donut_work/1 with valid data creates a donut_work" do
      assert {:ok, %DonutWork{} = _donut_work} = DonutWorks.create_donut_work(@valid_attrs)
    end

    test "create_donut_work/1 with invalid data does not create a donut_work" do
      assert {:error, %Ecto.Changeset{}} = DonutWorks.create_donut_work(@invalid_attrs)
    end

    test "delete_donut_work/1 deletes a donut_work" do
      donut_work = DonutWorks.create_donut_work!(@valid_attrs)

      assert {:ok, %DonutWork{} = _donut_work} = DonutWorks.delete_donut_work(donut_work)
      assert Enum.empty?(DonutWorks.list_donut_works())
    end

    test "update_donut_work/2 updates a donut_work" do
      donut_work = DonutWorks.create_donut_work!(@valid_attrs)

      assert {:ok, %DonutWork{} = donut_work} =
               DonutWorks.update_donut_work(donut_work, %{status: "error", error: "failed"})

      assert donut_work.status == "error"
    end

    test "update_donut_work/2 with invalid attributes returns an error" do
      donut_work = DonutWorks.create_donut_work!(@valid_attrs)

      assert {:error, %Ecto.Changeset{}} =
               DonutWorks.update_donut_work(donut_work, %{work_id: 123})
    end
  end
end
