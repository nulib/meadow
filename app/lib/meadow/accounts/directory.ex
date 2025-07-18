defmodule Meadow.Accounts.Directory do
  @moduledoc """
  Look up user info in SSO Directory Search Basic
  """

  alias Meadow.HTTP

  def find_user_by_netid(net_id), do: find_user(net_id, :netid)
  def find_user_by_email(email), do: find_user(email, :mail)

  def find_user(value, value_type \\ :netid) do
    url = directory_search_url(value, value_type)

    api_key =
      Application.get_env(:meadow, Meadow.Directory)
      |> Keyword.get(:api_key)

    case HTTP.get(url, apikey: api_key) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        case Jason.decode(body, keys: :atoms) do
          {:ok, %{results: [user | _]}} -> user
          {:ok, _} -> {:error, "Invalid response format: no user found"}
          {:error, _} -> {:error, "Invalid response format"}
        end

      {:ok, %HTTPoison.Response{status_code: 404}} ->
        nil

      {:ok, %HTTPoison.Response{status_code: status}} when status in 400..599 ->
        {:error, "Error fetching user info: HTTP #{status}"}

      {:error, reason} ->
        {:error, "Failed to fetch user info: #{reason}"}
    end
  end

  defp directory_search_url(value, value_type) do
    Application.get_env(:meadow, Meadow.Directory)
    |> Keyword.get(:base_url)
    |> Path.join("res/#{value_type}/bas/#{value}")
  end
end
