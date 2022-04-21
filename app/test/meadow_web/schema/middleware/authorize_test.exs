defmodule MeadowWeb.Schema.Middleware.AuthorizeTest do
  use MeadowWeb.ConnCase, async: true

  alias MeadowWeb.Schema.Middleware.Authorize

  test "Authorize middleware checks against the current user's role in the context" do
    %{id: id} = user_fixture()

    resolution =
      %Absinthe.Resolution{}
      |> Map.put(:context, %{current_user: %{id: id, role: "Administrator"}})
      |> Authorize.call("Administrator")

    assert %{errors: []} = resolution
    assert %{current_user: %{id: ^id}} = resolution.context
  end

  test "Authorize middleware takes the argument :any to authorize all users" do
    %{id: id} = user_fixture()

    resolution =
      %Absinthe.Resolution{}
      |> Map.put(:context, %{current_user: %{id: id}})
      |> Authorize.call(:any)

    assert %{errors: []} = resolution
    assert %{current_user: %{id: ^id}} = resolution.context
  end

  test "Authorize middleware errors when the current user's role in the context does not match" do
    %{id: id} = user_fixture()

    resolution =
      %Absinthe.Resolution{}
      |> Map.put(:context, %{current_user: %{id: id, role: "User"}})
      |> Authorize.call("Administrator")

    assert %{errors: [%{message: "Forbidden", status: 403}]} = resolution
    assert %{} = resolution.context
  end

  test "Authorize middleware errors when the current user does not have a role" do
    %{id: id} = user_fixture()

    resolution =
      %Absinthe.Resolution{}
      |> Map.put(:context, %{current_user: %{id: id}})
      |> Authorize.call("Administrator")

    assert %{errors: [%{message: "Forbidden", status: 403}]} = resolution
    assert %{} = resolution.context
  end
end
