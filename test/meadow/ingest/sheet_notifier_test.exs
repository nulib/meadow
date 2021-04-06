defmodule Meadow.Ingest.SheetNotifierTest do
  use Meadow.DataCase
  alias Meadow.Ingest.SheetNotifier

  describe "handle_notification/4" do
    test "fails gracefully when sheet is not found" do
      assert {:noreply, nil} ==
               SheetNotifier.handle_notification(
                 :ingest_sheets,
                 :insert,
                 %{id: Ecto.UUID.generate()},
                 nil
               )
    end
  end
end
