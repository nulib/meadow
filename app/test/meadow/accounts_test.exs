defmodule Meadow.AccountsTest do
  use ExUnit.Case
  use Meadow.Constants

  import Assertions
  import Meadow.TestHelpers

  alias Ecto.Adapters.SQL.Sandbox
  alias Meadow.Accounts
  alias Meadow.Accounts.Schemas.User, as: UserSchema
  alias Meadow.Accounts.User
  alias Meadow.Repo

  describe "user login" do
    setup do
      Sandbox.checkout(Meadow.Repo)
    end

    test "user doesn't exist" do
      assert Accounts.authorize_user_login(random_user(:unknown)) == {:error, "Unauthorized"}
    end

    test "user without access" do
      assert Accounts.authorize_user_login(random_user(:noAccess)) == {:error, "Unauthorized"}
    end

    test "user with access" do
      username = random_user(:access)

      with {result, user} <- Accounts.authorize_user_login(username) do
        assert result == :ok
        assert user.username == username
      end
    end

    test "add user role" do
      user = user_fixture(:staff_user)
      assert Repo.get(UserSchema, user.id) |> is_nil()
      assert {:ok, _} = Accounts.set_user_role(user.id, :editor)
      assert User.find(user.id).role == :editor
    end

    test "set user role" do
      user = user_fixture(:manager)
      assert User.find(user.id).role == :manager
      assert {:ok, _} = Accounts.set_user_role(user.id, :administrator)
      assert User.find(user.id).role == :administrator
    end

    test "remove user role" do
      user = user_fixture(:manager)
      assert User.find(user.id).role == :manager
      assert {:ok, _} = Accounts.set_user_role(user.id, nil)
      assert Repo.get(UserSchema, user.id) |> is_nil()
    end
  end

  test "list roles" do
    Accounts.list_roles()
    |> assert_lists_equal([
      "Superuser",
      "Administrator",
      "Manager",
      "Editor",
      "User"
    ])
  end
end
