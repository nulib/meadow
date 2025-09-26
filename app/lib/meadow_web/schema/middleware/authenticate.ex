defmodule MeadowWeb.Schema.Middleware.Authenticate do
  @moduledoc """
  Checks if there is a current user is in the Absinthe context

  """
  @behaviour Absinthe.Middleware

  def call(resolution, _) do
    case resolution.context do
      %{current_user: %{id: user_id}} when not is_nil(user_id) ->
        resolution

      _ ->
        resolution
        |> Absinthe.Resolution.put_result({:error, %{message: "Unauthorized", status: 401}})
    end
  end
end
