defmodule MeadowWeb.ConnCase do
  @moduledoc """
  This module defines the test case to be used by
  tests that require setting up a connection.

  Such tests rely on `Phoenix.ConnTest` and also
  import other functionality to make it easier
  to build common data structures and query the data layer.

  Finally, if the test case interacts with the database,
  it cannot be async. For this reason, every test runs
  inside a transaction which is reset at the beginning
  of the test unless the test case is marked as async.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      alias Meadow.Accounts.Schemas.User
      alias MeadowWeb.Router.Helpers, as: Routes

      # Import conveniences for testing with connections
      import Meadow.TestHelpers
      import Phoenix.ConnTest
      import Plug.Conn

      # The default endpoint for testing
      @endpoint MeadowWeb.Endpoint

      defp auth_user(conn, user) do
        conn
        |> Plug.Test.init_test_session(
          current_user: %Meadow.Accounts.User{
            id: user.username,
            username: user.username,
            display_name: user.display_name,
            email: user.email,
            role: user.role
          }
        )
      end
    end
  end

  setup do
    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end
end
