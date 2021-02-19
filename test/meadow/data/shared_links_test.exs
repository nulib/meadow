defmodule Meadow.Data.SharedLinksTest do
  use Meadow.DataCase
  alias Meadow.Data.SharedLinks

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
