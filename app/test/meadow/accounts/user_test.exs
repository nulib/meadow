defmodule Meadow.Accounts.User.Test do
  use ExUnit.Case

  import Meadow.TestHelpers

  alias Ecto.Adapters.SQL.Sandbox
  alias Meadow.Accounts.User

  describe "Meadow.Accounts.User.find/1" do
    setup do
      old_level = Logger.level()
      Logger.configure(level: :debug)
      on_exit(fn -> Logger.configure(level: old_level) end)

      Sandbox.checkout(Meadow.Repo)

      :ok
    end

    test "find user" do
      with user <- random_user(:manager) do
        user = User.find(user)
        assert is_struct(user)
      end
    end

    test "staff user" do
      with user <- random_user(:staff_user) do
        assert User.find(user) |> Map.get(:role) == :user
      end
    end

    test "faculty user" do
      with user <- random_user(:faculty_user) do
        assert User.find(user) |> Map.get(:role) == :user
      end
    end

    test "student user (explicit access)" do
      with user <- random_user(:student_user) do
        assert User.find(user) |> Map.get(:role) == :user
      end
    end

    test "user with no access" do
      with user <- random_user(:noAccess) do
        assert User.find(user) == nil
      end
    end

    test "user not found" do
      assert is_nil(User.find("unknownUser"))
    end
  end
end
