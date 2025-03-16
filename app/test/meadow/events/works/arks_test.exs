defmodule Meadow.Events.Works.ArksTest do
  use Meadow.DataCase, async: false

  alias Meadow.Ark
  alias Meadow.Data.Schemas.Work
  alias Meadow.Data.Works
  alias Meadow.Repo

  import Assertions
  import Ecto.Query
  import ExUnit.CaptureLog
  import Meadow.TestHelpers

  def assert_ark_status(work, expected_status) do
    assert_async(timeout: 2000) do
      case expected_status do
        :any -> assert {:ok, %Ark{status: _}} = get_ark_for_work(work)
        status -> assert {:ok, %Ark{status: ^status}} = get_ark_for_work(work)
      end
    end

    work
  end

  def get_ark_for_work(work) do
    Works.get_work(work.id)
    |> Map.get(:descriptive_metadata)
    |> Map.get(:ark)
    |> Ark.get()
  end

  @moduletag walex: [Meadow.Events.Works.Arks]
  describe "Meadow.Events.Works.Arks" do
    setup do
      start_supervised!(Meadow.Events.Works.Arks.Processor)

      work =
        work_fixture(%{
          published: false,
          visibility: %{id: "RESTRICTED", scheme: "visibility"}
        })

      {:ok, %{work: work}}
    end

    test "ark minted on insert", %{work: work} do
      assert_ark_status(work, :any)
    end

    test "never published / reserved", %{work: work} do
      assert_ark_status(work, "reserved")
    end

    test "published to unpublished / unavailable | unpublished", %{work: work} do
      work
      |> assert_ark_status(:any)
      |> Works.update_work!(%{published: true, visibility: %{id: "OPEN", scheme: "visibility"}})
      |> assert_ark_status("public")
      |> Works.update_work!(%{published: false})
      |> assert_ark_status("unavailable | unpublished")
    end

    test "private / unavilable | restricted", %{work: work} do
      work
      |> assert_ark_status(:any)
      |> Works.update_work!(%{published: true})
      |> assert_ark_status("unavailable | restricted")
    end

    test "public / public", %{work: work} do
      work
      |> assert_ark_status(:any)
      |> Works.update_work!(%{published: true, visibility: %{id: "OPEN", scheme: "visibility"}})
      |> assert_ark_status("public")
    end

    test "institution / public", %{work: work} do
      work
      |> assert_ark_status(:any)
      |> Works.update_work!(%{
        published: true,
        visibility: %{id: "AUTHENTICATED", scheme: "visibility"}
      })
      |> assert_ark_status("public")
    end

    test "delete never-published work", %{work: work} do
      assert_ark_status(work, :any)
      ark = Works.get_work(work.id).descriptive_metadata.ark

      Works.delete_work(work)

      assert_async(timeout: 2000) do
        assert {:error, "error: bad request - no such identifier"} = Ark.get(ark)
      end
    end

    test "delete published work", %{work: work} do
      assert_ark_status(work, :any)
      ark = Works.get_work(work.id).descriptive_metadata.ark

      work
      |> Works.update_work!(%{
        published: true,
        visibility: %{id: "AUTHENTICATED", scheme: "visibility"}
      })
      |> assert_ark_status("public")

      Works.delete_work(work)

      assert_async(timeout: 2000) do
        assert {:ok, %{status: "unavailable | withdrawn"}} = Ark.get(ark)
      end
    end

    test "update ark metadata", %{work: work} do
      CaptureLog

      log =
        capture_log(fn ->
          Works.update_work!(work, %{descriptive_metadata: %{title: "New Title"}})
          :timer.sleep(250)
        end)

      refute String.contains?(log, "No ARK update needed for work: #{work.id}")

      log =
        capture_log(fn ->
          Works.update_work!(work, %{administrative_metadata: %{project_cycle: "Next"}})
          :timer.sleep(250)
        end)

      assert String.contains?(log, "No ARK update needed for work: #{work.id}")
    end
  end

  describe "Rate limiting" do
    setup do
      start_supervised!(
        {Meadow.Events.Works.Arks.Processor,
         token_count: 5, interval: 2_000, replenish_count: 1, replenish_interval: 1_000}
      )

      :ok
    end

    test "ark events are rate limited" do
      test_query =
        from(Work, where: fragment("descriptive_metadata ->> 'ark' IS NOT NULL"))

      # Make sure only 5 requests are processed within the first 2 seconds
      1..10
      |> Enum.map(fn i -> work_fixture(%{descriptive_metadata: %{title: "Title ##{i}"}}) end)

      :timer.sleep(1000)
      assert Repo.aggregate(test_query, :count) == 5

      # Make sure 2 more requests are processed after 2 seconds
      assert_async(timeout: 2000) do
        assert Repo.aggregate(test_query, :count) == 7
      end
    end
  end
end
