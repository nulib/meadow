defmodule Meadow.ArkTest do
  use ExUnit.Case, async: false

  alias Meadow.Ark
  alias Meadow.Utils.ArkClient.MockServer

  @ark_format ~r'^ark:/12345/nu2\d{8}$'
  @fields ~w(creator title publisher publication_year resource_type status target)a

  setup do
    MockServer.send_to(self())
  end

  describe "mint/1" do
    test "no arguments" do
      with {:ok, result} <- Ark.mint() do
        assert String.match?(result.ark, @ark_format)
        Enum.each(@fields, &assert(result |> Map.get(&1) |> is_nil()))
      end

      assert_received({:post, :credentials, {"mockuser", "mockpassword"}})
      assert_received({:post, :body, "_profile: datacite"})
    end

    test "attribute list argument" do
      source = [target: "http://example.edu/work", creator: "Lovelace, Ada"]

      with {:ok, result} <- Ark.mint(source) do
        assert String.match?(result.ark, @ark_format)
        Enum.each(@fields, &assert(Map.get(result, &1) == Keyword.get(source, &1)))
      end

      assert_received({:post, :credentials, {"mockuser", "mockpassword"}})

      expected =
        [
          "_profile: datacite",
          "datacite.creator: Lovelace, Ada",
          "_target: http://example.edu/work"
        ]
        |> Enum.join("\n")

      assert_received({:post, :body, ^expected})
    end

    test "map argument" do
      source = %{target: "http://example.edu/work", creator: "Lovelace, Ada"}

      with {:ok, result} <- Ark.mint(source) do
        assert String.match?(result.ark, @ark_format)
        Enum.each(@fields, &assert(Map.get(result, &1) == Map.get(source, &1)))
      end

      assert_received({:post, :credentials, {"mockuser", "mockpassword"}})

      expected =
        [
          "_profile: datacite",
          "datacite.creator: Lovelace, Ada",
          "_target: http://example.edu/work"
        ]
        |> Enum.join("\n")

      assert_received({:post, :body, ^expected})
    end

    test "Meadow.Ark argument" do
      source = %Meadow.Ark{target: "http://example.edu/work", creator: "Lovelace, Ada"}

      with {:ok, result} <- Ark.mint(source) do
        assert String.match?(result.ark, @ark_format)
        Enum.each(@fields, &assert(Map.get(result, &1) == Map.get(source, &1)))
      end

      assert_received({:post, :credentials, {"mockuser", "mockpassword"}})

      expected =
        [
          "_profile: datacite",
          "datacite.creator: Lovelace, Ada",
          "_target: http://example.edu/work"
        ]
        |> Enum.join("\n")

      assert_received({:post, :body, ^expected})
    end
  end

  describe "get/1" do
    setup do
      {:ok, result} = Ark.mint(target: "http://example.edu/work", creator: "Lovelace, Ada")
      {:ok, fixture: result}
    end

    test "known ARK", %{fixture: fixture} do
      assert {:ok, fixture} == Ark.get(fixture.ark)
    end

    test "unknown ARK" do
      assert {:error, "error: bad request - no such identifier"} == Ark.get("ark:/99999/invalid")
    end
  end

  describe "put/1" do
    setup do
      {:ok, result} = Ark.mint(target: "http://example.edu/work", creator: "Lovelace, Ada")
      {:ok, fixture: result}
    end

    test "valid ARK", %{fixture: fixture} do
      update = Map.put(fixture, :title, "A New Title for This ARK")
      assert {:ok, update} == Ark.put(update)
      assert {:ok, update} == Ark.get(fixture.ark)
      assert_received({:put, :credentials, {"mockuser", "mockpassword"}})

      expected =
        [
          "_profile: datacite",
          "datacite.creator: Lovelace, Ada",
          "_target: http://example.edu/work",
          "datacite.title: A New Title for This ARK"
        ]
        |> Enum.join("\n")

      assert_received({:put, :body, ^expected})
    end

    test "invalid ARK" do
      assert {:error, "cannot update an ARK without an ID"} == Ark.put(%Ark{})
    end
  end
end
