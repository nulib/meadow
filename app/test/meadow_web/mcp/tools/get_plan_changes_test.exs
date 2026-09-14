defmodule MeadowWeb.MCP.Tools.GetPlanChangesTest do
  use MeadowWeb.MCPCase

  alias Meadow.Data.Planner

  describe "GetPlanChanges Tool" do
    test "echoes repeating free-text operations as bare strings, not {id, value} objects" do
      work = work_fixture()
      {:ok, plan} = Planner.create_plan(%{prompt: "Test plan"})

      {:ok, _change} =
        Planner.create_plan_change(%{
          plan_id: plan.id,
          work_id: work.id,
          replace: %{
            descriptive_metadata: %{
              alternate_title: [
                %{id: Ecto.UUID.generate(), value: "Short A"},
                %{id: Ecto.UUID.generate(), value: "Short B"}
              ]
            }
          },
          status: :proposed
        })

      {:ok, [{:text, response} | _]} =
        call_tool("get_plan_changes", %{"plan_id" => plan.id, "work_id" => work.id})
        |> parse_response()

      %{"changes" => [change | _]} = Jason.decode!(response)

      # The agent must see plain strings so it doesn't mistake them for terms.
      assert get_in(change, ["replace", "descriptive_metadata", "alternate_title"]) ==
               ["Short A", "Short B"]
    end
  end
end
