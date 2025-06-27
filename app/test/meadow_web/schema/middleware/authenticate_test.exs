defmodule MeadowWeb.Schema.Middleware.AuthenticateTest do
  use Meadow.DataCase
  use MeadowWeb.ConnCase, async: true

  alias MeadowWeb.Schema.Middleware.Authenticate

  test "Authenticate middleware does not error when there is a current user in the context" do
    %{id: id} = user_fixture()

    resolution =
      %Absinthe.Resolution{}
      |> Map.put(:context, %{current_user: %{id: id}})
      |> Authenticate.call({})

    assert %{errors: []} = resolution
    assert %{current_user: %{id: ^id}} = resolution.context
  end

  test "Authenticate middleware errors when there is not a current user in the context" do
    resolution =
      %Absinthe.Resolution{}
      |> Map.put(:context, %{})
      |> Authenticate.call({})

    assert %{errors: [%{message: "Unauthorized", status: 401}]} = resolution
    assert %{} = resolution.context
  end
end
