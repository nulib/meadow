defmodule MeadowWeb.SubscriptionCase do
  @moduledoc """
  Test case for testing Absinthe Subscriptions.
  """

  use ExUnit.CaseTemplate
  alias Absinthe.Phoenix.SubscriptionTest

  using do
    quote do
      use MeadowWeb.ChannelCase
      use Wormwood.GQLCase
      use SubscriptionTest, schema: MeadowWeb.Schema
      import Meadow.TestHelpers
      import MeadowWeb.SubscriptionCase
      import Phoenix.ConnTest
      import Plug.Conn

      defmacro subscribe_gql(socket, opts \\ []) do
        quote do
          if is_nil(@_wormwood_gql_query) do
            raise WormwoodSetupError, reason: :missing_declaration
          end

          push_doc(unquote(socket), @_wormwood_gql_query, unquote(opts))
        end
      end

      setup do
        {:ok, socket} = Phoenix.ChannelTest.connect(MeadowWeb.UserSocket, %{})
        {:ok, socket} = SubscriptionTest.join_absinthe(socket)

        {:ok, socket: socket}
      end
    end
  end
end
