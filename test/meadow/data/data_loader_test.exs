defmodule Meadow.Data.DataLoaderTest do
  use ExUnit.Case
  alias Ecto.Adapters.SQL.Sandbox
  alias Meadow.Data.DataLoader
  alias Meadow.Repo
  doctest Meadow.Data.DataLoader

  setup do
    # Explicitly get a connection before each test
    :ok = Sandbox.checkout(Repo)
    # Setting the shared mode must be done only after checkout
    Sandbox.mode(Repo, {:shared, self()})
  end

  describe "insert_data" do
    test "seeds the database" do
      assert :ok = DataLoader.insert_data(1)
    end
  end
end
