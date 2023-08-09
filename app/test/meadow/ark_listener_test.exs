defmodule Meadow.ArkListenerTest do
  use Meadow.DataCase

  alias Meadow.{Ark, ArkListener}
  alias Meadow.Data.Works

  import Meadow.TestHelpers

  def update_work(work, attrs) do
    {:ok, work} = Works.update_work(work, attrs)
    mock_database_notification(ArkListener, :works, :update, [work.id])
    work
  end

  describe "ArkListener" do
    setup do
      work =
        work_fixture(%{published: false, visibility: %{id: "RESTRICTED", scheme: "visibility"}})

      mock_database_notification(ArkListener, :works, :insert, [work.id])

      with work <- Works.get_work(work.id) do
        {:ok, %{work: work, ark: work.descriptive_metadata.ark}}
      end
    end

    test "ark minted on insert", %{ark: ark} do
      assert {:ok, %{status: _}} = Ark.get(ark)
    end

    test "never published / reserved", %{ark: ark} do
      assert {:ok, %Ark{status: "reserved"}} = Ark.get(ark)
    end

    test "published to unpublished / unavailable | unpublished", %{work: work, ark: ark} do
      work |> update_work(%{published: true}) |> update_work(%{published: false})
      assert {:ok, %Ark{status: "unavailable | unpublished"}} = Ark.get(ark)
    end

    test "private / unavilable | restricted", %{work: work, ark: ark} do
      work |> update_work(%{published: true})
      assert {:ok, %Ark{status: "unavailable | restricted"}} = Ark.get(ark)
    end

    test "public / public", %{work: work, ark: ark} do
      work |> update_work(%{published: true, visibility: %{id: "OPEN", scheme: "visibility"}})
      assert {:ok, %Ark{status: "public"}} = Ark.get(ark)
    end

    test "institution / public", %{work: work, ark: ark} do
      work
      |> update_work(%{published: true, visibility: %{id: "AUTHENTICATED", scheme: "visibility"}})

      assert {:ok, %Ark{status: "public"}} = Ark.get(ark)
    end

    test "delete never-published work", %{work: work, ark: ark} do
      work |> Works.delete_work()
      mock_database_notification(ArkListener, "works", :delete, [work.id])
      assert {:error, "error: bad request - no such identifier"} = Ark.get(ark)
    end

    test "delete published work", %{work: work, ark: ark} do
      work
      |> update_work(%{published: true})
      |> Works.delete_work()

      mock_database_notification(ArkListener, "works", :delete, [work.id])
      assert {:ok, %{status: "unavailable | withdrawn"}} = Ark.get(ark)
    end
  end
end
