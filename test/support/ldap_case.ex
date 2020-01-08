defmodule Meadow.LdapCase do
  @moduledoc """
  This module defines the setup for tests requiring
  access to LDAP services.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      alias Meadow.Accounts.Ldap
      import Meadow.LdapCase
    end
  end

  setup do
    with {:ok, connection} <- Exldap.connect() do
      ["Meadow", "TestUsers"]
      |> Enum.each(fn ou ->
        attributes = [
          {'objectClass', ['organizationalUnit']},
          {'objectClass', ['top']},
          {'ou', [to_charlist(ou)]},
          {'name', [to_charlist(ou)]}
        ]

        :eldap.add(
          connection,
          to_charlist("OU=#{ou},DC=library,DC=northwestern,DC=edu"),
          attributes
        )
      end)
    end

    on_exit(fn ->
      with {:ok, connection} <- Exldap.connect() do
        ["Meadow", "TestUsers"]
        |> Enum.each(fn ou ->
          {:ok, children} =
            Exldap.search(connection,
              base: "OU=#{ou},DC=library,DC=northwestern,DC=edu",
              scope: :eldap.wholeSubtree(),
              filter: Exldap.equalityMatch("objectClass", "top")
            )

          Enum.reverse(children)
          |> Enum.each(fn leaf ->
            :eldap.delete(connection, leaf.object_name)
          end)
        end)
      end
    end)

    :ok
  end

  def create_user(username) do
    with {:ok, connection} <- Exldap.connect(),
         user_dn <-
           "CN=#{username},OU=TestUsers,DC=library,DC=northwestern,DC=edu" |> to_charlist() do
      attributes = [
        {'objectClass', ['user']},
        {'objectClass', ['person']},
        {'objectClass', ['organizationalPerson']},
        {'objectClass', ['top']},
        {'sn', [to_charlist(username)]}
      ]

      case :eldap.add(connection, user_dn, attributes) do
        :ok -> to_string(user_dn)
        {:error, :entryAlreadyExists} -> to_string(user_dn)
        other -> other
      end
    end
  end

  def create_users([]), do: []

  def create_users([user | users]) do
    [create_user(user) | create_users(users)]
  end
end
