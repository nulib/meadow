defmodule Meadow.Data.SharedLinksTest do
  use Meadow.DataCase
  use Meadow.IndexCase
  alias Meadow.Config
  alias Meadow.Data.{Indexer, SharedLinks, Works}

  @query %{query: %{match_all: %{}}}

  describe "single shared links" do
    setup do
      with index_url <- Config.elasticsearch_url(),
           index <- Config.shared_links_index() do
        Elastix.Index.delete(index_url, index)
        Elastix.Index.create(index_url, index, %{})
        on_exit(fn -> Elastix.Index.delete(index_url, index) end)
      end

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
      assert header == ~w(work_id shared_link expires accession_number title description)
      assert length(data) == length(works)

      # Make sure there's at least one work that should have a public link
      assert works
             |> Enum.find(fn
               %{visibility: %{id: "OPEN"}, published: true} -> true
               _ -> false
             end)

      data
      |> Enum.each(fn row ->
        map = header |> Enum.zip(row) |> Enum.into(%{})

        with work <- works |> Enum.find(fn work -> work.id == map["work_id"] end) do
          assert map["accession_number"] == work.accession_number

          case work do
            %{visibility: %{id: "OPEN"}, published: true} ->
              assert map["shared_link"] =~ ~r"/items/"
              assert map["expires"] == "Never"

            _ ->
              assert map["shared_link"] =~ ~r"/shared/"
              assert byte_size(map["expires"]) == byte_size("2021-05-07T12:02:38Z")
              assert NaiveDateTime.from_iso8601!(map["expires"])
          end
        end
      end)
    end
  end
end
