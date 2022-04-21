defmodule Meadow.ArkTest do
  use ExUnit.Case, async: false

  alias Meadow.Ark
  alias Meadow.Utils.ArkClient.MockServer

  @ark_format ~r'^ark:/12345/nu2\d{8}$'
  @fields ~w(creator title publisher publication_year resource_type status target)a
  @valid_resource_types ~w(Audiovisual Collection Dataset Event Image InteractiveResource Model
    PhysicalObject Service Software Sound Text Workflow Other)
  @valid_statuses ~w(public reserved)

  setup do
    MockServer.send_to(self())
  end

  describe "mint/1" do
    test "missing status" do
      assert {:error, error} = Ark.mint()
      assert error == "error: bad request - _status: missing mandatory value"
    end

    test "valid status" do
      @valid_statuses
      |> Enum.each(
        &assert {:ok, _result} = Ark.mint(status: &1, target: "http://example.edu/work")
      )
    end

    test "invalid status" do
      assert {:error, error} = Ark.mint(status: "meh", target: "http://example.edu/work")
      assert error == "error: bad request - _status: invalid value"
    end

    test "valid resource type" do
      @valid_resource_types
      |> Enum.each(
        &assert {:ok, _result} =
                  Ark.mint(
                    status: "reserved",
                    target: "http://example.edu/work",
                    resource_type: &1
                  )
      )
    end

    test "invalid resource type" do
      assert {:error, error} =
               Ark.mint(
                 status: "reserved",
                 target: "http://example.edu/work",
                 resource_type: "JustMakeSomethingUp"
               )

      assert error == "error: bad request - datacite.resourcetype: invalid value"
    end

    test "minimal arguments" do
      with {:ok, result} <- Ark.mint(status: "reserved") do
        assert String.match?(result.ark, @ark_format)
        Enum.each(@fields, &assert(result |> Map.get(&1) |> is_nil()))
      end

      assert_received({:post, :credentials, {"mockuser", "mockpassword"}})
      assert_received({:post, :body, "_profile: datacite\n_status: reserved"})
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
      {:ok, result} =
        Ark.mint(status: "reserved", target: "http://example.edu/work", creator: "Lovelace, Ada")

      {:ok, fixture: result}
    end

    test "known ARK", %{fixture: fixture} do
      assert {:ok, fixture} == Ark.get(fixture.ark)
    end

    test "unknown ARK" do
      assert {:error, "error: bad request - no such identifier"} == Ark.get("ark:/99999/invalid")
    end

    test "can handle colons in attribute values" do
      {:ok, result} =
        Ark.mint(
          status: "reserved",
          target: "http://example.edu/work",
          title: "Before colon : after colon"
        )

      assert {:ok, %Ark{title: "Before colon : after colon"}} = Ark.get(result.ark)
    end
  end

  describe "put/1" do
    setup do
      {:ok, result} =
        Ark.mint(status: "reserved", target: "http://example.edu/work", creator: "Lovelace, Ada")

      {:ok, fixture: result}
    end

    test "valid ARK", %{fixture: fixture} do
      update = Map.put(fixture, :title, "A 100% New Title for This ARK!")
      assert {:ok, update} == Ark.put(update)
      assert {:ok, update} == Ark.get(fixture.ark)
      assert_received({:put, :credentials, {"mockuser", "mockpassword"}})

      expected =
        [
          "_profile: datacite",
          "datacite.creator: Lovelace, Ada",
          "_status: reserved",
          "_target: http://example.edu/work",
          "datacite.title: A 100% New Title for This ARK!"
        ]
        |> Enum.join("\n")

      assert_received({:put, :body, ^expected})
    end

    test "invalid ARK" do
      assert {:error, "cannot update an ARK without an ID"} == Ark.put(%Ark{})
    end
  end

  describe "mock ARK server" do
    setup tags do
      fixtures =
        0..tags[:arks]
        |> Enum.map(fn i ->
          with {:ok, result} <-
                 Ark.mint(
                   status: "reserved",
                   target: "http://example.edu/work#{i}",
                   creator: "Creator ##{i}"
                 ) do
            result
          end
        end)

      {:ok, fixtures: fixtures}
    end

    @tag arks: 100
    test "creates unique values", %{fixtures: fixtures} do
      with arks <- Enum.map(fixtures, &Map.get(&1, :ark)) do
        assert arks == Enum.uniq(arks)
      end
    end
  end
end
