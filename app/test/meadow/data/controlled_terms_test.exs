defmodule Meadow.Data.ControlledTermsTest do
  use Meadow.AuthorityCase
  use Meadow.DataCase

  alias Meadow.Data.ControlledTerms
  alias Meadow.Data.Schemas.ControlledTermCache
  alias Meadow.Repo

  doctest Meadow.Data.ControlledTerms, import: true, only: [{:terms_equal?, 2}]

  setup do
    ControlledTerms.clear!()
    :ok
  end

  describe "fetch/1" do
    test "cache miss" do
      assert {{:ok, :miss}, term} = ControlledTerms.fetch("mock1:result1")
      assert term == %{id: "mock1:result1", label: "First Result", variants: []}
    end

    test "memory cache hit" do
      assert {{:ok, :miss}, _term} = ControlledTerms.fetch("mock1:result1")
      assert {{:ok, :memory}, term} = ControlledTerms.fetch("mock1:result1")
      assert term == %{id: "mock1:result1", label: "First Result", variants: []}
    end

    test "db cache hit" do
      assert {{:ok, :miss}, _term} = ControlledTerms.fetch("mock1:result1")
      Cachex.clear!(Meadow.Cache.ControlledTerms)
      assert {{:ok, :db}, term} = ControlledTerms.fetch("mock1:result1")
      assert term == %{id: "mock1:result1", label: "First Result", variants: []}
    end

    test "invalid term" do
      assert {:error, :unknown_authority} == ControlledTerms.fetch("mock0:result0")
    end
  end

  describe "fetch!/1" do
    test "cache miss" do
      assert term = ControlledTerms.fetch!("mock1:result1")
      assert term == %{id: "mock1:result1", label: "First Result", variants: []}
    end

    test "memory cache hit" do
      assert _term = ControlledTerms.fetch!("mock1:result1")
      assert term = ControlledTerms.fetch!("mock1:result1")
      assert term == %{id: "mock1:result1", label: "First Result", variants: []}
    end

    test "db cache hit" do
      assert _term = ControlledTerms.fetch!("mock1:result1")
      Cachex.clear!(Meadow.Cache.ControlledTerms)
      assert term = ControlledTerms.fetch!("mock1:result1")
      assert term == %{id: "mock1:result1", label: "First Result", variants: []}
    end

    test "invalid term" do
      assert_raise(RuntimeError, fn -> ControlledTerms.fetch!("mock0:result0") end)
    end
  end

  describe "clear!" do
    setup do
      ControlledTerms.fetch("mock1:result1")
      ControlledTerms.fetch("mock1:result2")
      ControlledTerms.fetch("mock2:result3")
      :ok
    end

    test "clear!/0" do
      assert {3, nil} == ControlledTerms.clear!()
      assert {{:ok, :miss}, _} = ControlledTerms.fetch("mock1:result1")
      assert {{:ok, :miss}, _} = ControlledTerms.fetch("mock1:result2")
      assert {{:ok, :miss}, _} = ControlledTerms.fetch("mock2:result3")
    end

    test "clear!/1" do
      assert {1, nil} == ControlledTerms.clear!("mock1:result2")
      assert {{:ok, :memory}, _} = ControlledTerms.fetch("mock1:result1")
      assert {{:ok, :miss}, _} = ControlledTerms.fetch("mock1:result2")
      assert {{:ok, :memory}, _} = ControlledTerms.fetch("mock2:result3")
    end
  end

  describe "expire/2" do
    setup do
      naive_secs_ago = fn s ->
        NaiveDateTime.utc_now()
        |> NaiveDateTime.add(-s)
        |> NaiveDateTime.truncate(:second)
      end

      ControlledTerms.fetch("mock1:result1")
      ControlledTerms.fetch("mock1:result2")
      ControlledTerms.fetch("mock2:result3")

      %ControlledTermCache{id: "mock1:result1"}
      |> Ecto.Changeset.change(%{updated_at: naive_secs_ago.(300)})
      |> Repo.update!()

      %ControlledTermCache{id: "mock1:result2"}
      |> Ecto.Changeset.change(%{updated_at: naive_secs_ago.(600)})
      |> Repo.update!()

      %ControlledTermCache{id: "mock2:result3"}
      |> Ecto.Changeset.change(%{updated_at: naive_secs_ago.(600)})
      |> Repo.update!()

      :ok
    end

    test "expire on age" do
      assert {2, nil} == ControlledTerms.expire!(500)
      assert {{:ok, :db}, _} = ControlledTerms.fetch("mock1:result1")
      assert {{:ok, :miss}, _} = ControlledTerms.fetch("mock1:result2")
      assert {{:ok, :miss}, _} = ControlledTerms.fetch("mock2:result3")
    end

    test "expire on age and prefix" do
      assert {2, nil} == ControlledTerms.expire!(200, "mock1:")
      assert {{:ok, :miss}, _} = ControlledTerms.fetch("mock1:result1")
      assert {{:ok, :miss}, _} = ControlledTerms.fetch("mock1:result2")
      assert {{:ok, :db}, _} = ControlledTerms.fetch("mock2:result3")
    end
  end

  describe "extract_unique_terms/1" do
    setup do
      {data, _} = Code.eval_file("test/fixtures/csv/work_fixtures.exs")
      {:ok, %{data: data}}
    end

    test "extracts all terms as a flat list", %{data: data} do
      with result <- ControlledTerms.extract_unique_terms(data) do
        assert Enum.all?(result, &is_binary/1)
        assert result == Enum.uniq(result)
        assert length(result) == 51
      end
    end
  end
end
