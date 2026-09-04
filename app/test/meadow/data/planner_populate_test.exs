defmodule Meadow.Data.PlannerPopulateTest do
  @moduledoc """
  Creating a plan with a real search query auto-populates one empty
  PlanChange per matching work.
  """
  use Meadow.DataCase
  use Meadow.IndexCase

  alias Meadow.Data.{Indexer, Planner}
  alias Meadow.Data.Schemas.PlanChange

  describe "create_plan/1 with a search query" do
    setup do
      works = [work_fixture(), work_fixture(), work_fixture()]
      Indexer.reindex_all()
      {:ok, works: works}
    end

    test "creates an empty plan change for each matching work", %{works: works} do
      attrs = %{
        prompt: "Translate titles",
        query: ~s'{"query":{"match_all":{}}}',
        status: :proposed
      }

      assert {:ok, plan} = Planner.create_plan(attrs)

      changes = Planner.list_plan_changes(plan.id)
      assert length(changes) == length(works)

      assert MapSet.new(changes, & &1.work_id) == MapSet.new(works, & &1.id)

      Enum.each(changes, fn %PlanChange{} = change ->
        assert change.status == :pending
        assert change.add == %{}
        assert change.delete == %{}
        assert change.replace == %{}
      end)
    end
  end
end
