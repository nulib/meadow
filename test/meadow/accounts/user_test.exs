defmodule Meadow.Accounts.User.Test do
  use ExUnit.Case

  import ExUnit.CaptureLog
  import Meadow.TestHelpers

  alias Meadow.Accounts.User

  describe "Meadow.Accounts.User.find/1" do
    setup do
      old_level = Logger.level()
      Logger.configure(level: :debug)
      on_exit(fn -> Logger.configure(level: old_level) end)
      Cachex.clear!(Meadow.Cache.Users)

      :ok
    end

    test "get user from LDAP" do
      with user <- random_user("TestManagers") do
        assert capture_log(fn ->
                 user = User.find(user)
                 assert is_struct(user)
                 assert user.role == "Manager"
               end) =~ "User #{user} found in LDAP and added to cache"
      end
    end

    test "get user from cache" do
      with user <- random_user("TestManagers") do
        User.find(user)

        assert capture_log(fn ->
                 user = User.find(user)
                 assert is_struct(user)
                 assert user.role == "Manager"
               end) =~ "User #{user} found in cache"
      end
    end

    test "user not found" do
      with user <- random_user(:unknown) do
        assert capture_log(fn ->
                 assert is_nil(User.find(user))
               end) =~ "User #{user} not found"
      end
    end
  end
end
