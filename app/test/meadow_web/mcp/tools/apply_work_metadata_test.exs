defmodule MeadowWeb.MCP.Tools.ApplyWorkMetadataTest do
  use MeadowWeb.MCPCase

  alias Meadow.AI.Provenance
  alias MeadowWeb.MCP.Tools.ApplyWorkMetadata

  describe "eval context guard" do
    test "refuses to execute when context.eval is true" do
      work = work_fixture(%{descriptive_metadata: %{title: "Guard Test"}})

      frame = %Anubis.Server.Frame{
        assigns: %{context: %{eval: true}}
      }

      args = %{
        work_id: work.id,
        description: "Should not be applied.",
        subjects: []
      }

      assert {:error, _reason, _frame} = ApplyWorkMetadata.execute(args, frame)

      # Verify work was NOT mutated
      fresh = Meadow.Data.Works.get_work!(work.id)
      assert fresh.descriptive_metadata.description == []
    end

    test "executes normally when eval context is absent" do
      work = work_fixture(%{descriptive_metadata: %{title: "Normal Test"}})
      frame = %Anubis.Server.Frame{}

      args = %{
        work_id: work.id,
        description: "A test description.",
        subjects: []
      }

      assert {:reply, _response, _frame} = ApplyWorkMetadata.execute(args, frame)

      fresh = Meadow.Data.Works.get_work!(work.id)
      assert fresh.descriptive_metadata.description == ["A test description."]
      assert fresh.descriptive_metadata.notes == []

      assert [
               %{
                 field_path: "descriptive_metadata.description",
                 origin: "ai_generated"
               },
               %{
                 field_path: "descriptive_metadata.subject",
                 origin: "ai_generated"
               }
             ] = Provenance.work_summary(work.id)
    end
  end
end
