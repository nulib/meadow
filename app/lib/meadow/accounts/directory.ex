defmodule Meadow.Accounts.Directory do
  @moduledoc """
  Look up user info in SSO Directory Search Basic
  """

  alias Meadow.HTTP

  def find_user_by_netid(net_id), do: find_user(net_id, :netid)
  def find_user_by_email(email), do: find_user(email, :mail)

  def find_user(value, value_type \\ :netid) do
    api_key =
      Application.get_env(:meadow, Meadow.Directory)
      |> Keyword.get(:api_key)

    HTTP.get(
      "res/:value_type/bas/:value",
      base_url: base_url(),
      path_params: %{value_type: to_string(value_type), value: value},
      headers: %{apikey: api_key}, decode_json: [keys: :atoms]
    )
    |> case do
      {:ok, %Req.Response{status: 200, body: body}} ->
        case body do
          %{results: [user | _]} -> user
          _ -> {:error, "Invalid response format: no user found"}
        end

      {:ok, %Req.Response{status: 404}} ->
        nil

      {:ok, %Req.Response{status: status}} when status in 400..599 ->
        {:error, "Error fetching user info: HTTP #{status}"}

      {:error, reason} ->
        {:error, "Failed to fetch user info: #{reason}"}
    end
  end

  defp base_url do
    Application.get_env(:meadow, Meadow.Directory)
    |> Keyword.get(:base_url)
  end
end
