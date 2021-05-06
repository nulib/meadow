defmodule Meadow.Data.SharedLinksTest do
  use Meadow.DataCase
  use Meadow.IndexCase
  alias Meadow.Data.{Indexer, SharedLinks, Works}

  @query %{query: %{match_all: %{}}}

  describe "single shared links" do
    setup do
      index_url = Application.get_env(:meadow, Meadow.ElasticsearchCluster) |> Keyword.get(:url)
      Elastix.Index.delete(index_url, "shared_links")
      on_exit(fn -> Elastix.Index.delete(index_url, "shared_links") end)

      :ok
    end

    test "generate/2" do
      work = work_fixture()
      assert {:ok, link} = SharedLinks.generate(work.id)
      assert link.work_id == work.id
      assert is_binary(link.shared_link_id)

      with remaining_time <- DateTime.diff(link.expires, DateTime.utc_now(), :millisecond) do
        assert remaining_time > 0
        assert remaining_time < Meadow.Config.shared_link_ttl()
      end
    end

    test "count/0" do
      work = work_fixture()
      assert SharedLinks.count() == 0
      SharedLinks.generate(work.id)
      assert SharedLinks.count() == 1
      SharedLinks.generate(work.id)
      assert SharedLinks.count() == 2
    end

    test "revoke/1" do
      work = work_fixture()
      assert {:ok, _link1} = SharedLinks.generate(work.id)
      assert {:ok, link2} = SharedLinks.generate(work.id)
      assert SharedLinks.count() == 2
      assert SharedLinks.revoke(link2.shared_link_id) == :ok
      assert SharedLinks.count() == 1
    end

    test "delete_expired/0" do
      work = work_fixture()
      assert {:ok, _link1} = SharedLinks.generate(work.id)
      assert {:ok, _link2} = SharedLinks.generate(work.id, -1000)
      assert SharedLinks.count() == 2
      assert SharedLinks.delete_expired() == {:ok, 1}
      assert SharedLinks.count() == 1
    end
  end

  describe "bulk shared links" do
    setup do
      prewarm_controlled_term_cache()

      fixture = exs_fixture("test/fixtures/csv/work_fixtures.exs")

      works =
        fixture
        |> Enum.map(fn work_data ->
          work_data |> Works.create_work!() |> Works.update_work!(work_data)
        end)

      Indexer.synchronize_index()

      {:ok, %{works: works}}
    end

    test "generate_many/1", %{works: works} do
      csv = SharedLinks.generate_many(@query) |> Enum.join("")
      [header | data] = CSV.parse_string(csv, skip_headers: false)
      assert header == ["work_id", "title", "description", "expires", "shared_link"]
      assert length(data) == length(works)

      # Make sure there's at least one work that should have a public link
      assert works
             |> Enum.find(fn
               %{visibility: %{id: "OPEN"}, published: true} -> true
               _ -> false
             end)

      data
      |> Enum.each(fn [work_id, _title, _description, expires, link] ->
        with work <- works |> Enum.find(fn work -> work.id == work_id end) do
          case work do
            %{visibility: %{id: "OPEN"}, published: true} ->
              assert link =~ ~r"/items/"
              assert expires == ""

            _ ->
              assert link =~ ~r"/shared/"
              assert NaiveDateTime.from_iso8601!(expires)
          end
        end
      end)
    end
  end
end
