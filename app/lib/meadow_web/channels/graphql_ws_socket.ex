defmodule MeadowWeb.GraphqlWsSocket do
  @moduledoc """
  GraphQL WebSocket handler using the graphql-ws protocol.
  Provides keepalive pings to maintain connection stability during long operations.
  """

  use Absinthe.GraphqlWS.Socket,
    schema: MeadowWeb.Schema,
    keepalive: 15_000

  @impl true
  def handle_init(_payload, socket) do
    {:ok, %{}, socket}
  end
end
