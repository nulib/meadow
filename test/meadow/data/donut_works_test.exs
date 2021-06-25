defmodule Meadow.Data.DonutWorksTest do
  use Meadow.DataCase

  alias Ecto.Adapters.SQL.Sandbox
  alias Meadow.Data.DonutWorks
  alias Meadow.Data.Schemas.DonutWork
  alias Meadow.Repo

  import Assertions

  describe "queries" do
    @valid_attrs %{
      work_id: Ecto.UUID.bingenerate(),
      manifest: "s3://migration-source/path/to/manifest.json",
      last_modified: DateTime.utc_now()
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

  describe "with_next_donut_work/1" do
    setup do
      Sandbox.mode(Repo, :auto)

      donut_works =
        1..3
        |> Enum.map(fn _ ->
          with id <- Ecto.UUID.generate() do
            DonutWorks.create_donut_work!(%{
              work_id: id,
              manifest: "s3://migration-source/#{id}.json",
              last_modified: DateTime.utc_now()
            })
          end
        end)

      on_exit(fn -> DonutWork |> Repo.delete_all() end)
      {:ok, %{donut_works: donut_works}}
    end

    test "locks and skips", %{donut_works: donut_works} do
      results =
        1..4
        |> Enum.map(fn _ ->
          Task.async(fn ->
            DonutWorks.with_next_donut_work(fn dw ->
              (:rand.uniform() * 1000) |> trunc() |> :timer.sleep()
              dw
            end)
          end)
        end)
        |> Task.await_many()
        |> Enum.map(fn {:ok, value} -> value end)

      assert_lists_equal(results, [nil | donut_works])
    end
  end
end
