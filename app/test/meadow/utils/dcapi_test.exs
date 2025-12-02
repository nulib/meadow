defmodule Meadow.Utils.DCAPITest do
  use ExUnit.Case

  alias Meadow.Utils.DCAPI

  describe "DCAPI.superuser_token/0" do
    test "generates a valid JWT token" do
      secret = Application.get_env(:meadow, :dc_api)[:v2]["api_token_secret"]

      {:ok, %{token: token, expires: expires_at}} = DCAPI.superuser_token()

      assert is_binary(token)
      assert %DateTime{} = expires_at

      {:ok, decoded_token} = :jwt.decode(token, secret)

      assert decoded_token["iss"] == "meadow"
      assert decoded_token["isSuperUser"] == true
      assert decoded_token["exp"] == DateTime.to_unix(expires_at)
    end
  end
end
