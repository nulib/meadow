defmodule Meadow.Directory.MockServer do
  @moduledoc """
  Mock NUSSO Directory server for testing Meadow.Accounts

  Also has the ability to send inter-process messages in order to make testing
  easier.
  """

  @cache Meadow.Directory.MockServer.Cache
  alias Meadow.Accounts.Schemas.User, as: UserSchema
  alias Meadow.Repo

  use Plug.Router
  plug(:match)
  plug(:dispatch)

  def prewarm do
    File.read!("test/fixtures/test_users.json")
    |> Jason.decode!()
    |> Enum.each(fn user ->
      user =
        case user do
          %{"_role" => role} ->
            UserSchema.changeset(%UserSchema{}, %{id: user["uid"], role: role})
            |> Repo.insert_or_update()

            Map.delete(user, "_role")

          _ ->
            user
        end

      Cachex.put!(@cache, {:netid, user["uid"]}, user)
      Cachex.put!(@cache, {:mail, user["mail"]}, user)
    end)
  end

  get "/directory-search/res/:field/bas/:value" do
    case Cachex.get!(@cache, {String.to_existing_atom(field), value}) do
      nil ->
        response =
          ~s[{"errorCode":404,"errorMessage":"No LDAP Data Found for = (#{field}=#{value})"}]

        conn
        |> put_resp_header("content-type", "application/json")
        |> send_resp(404, response)

      data ->
        conn
        |> put_resp_header("content-type", "application/json")
        |> send_resp(200, %{results: [data]} |> Jason.encode!())
    end
  end
end
