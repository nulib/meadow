defmodule Meadow.LdapCase do
  @moduledoc """
  This module defines the setup for tests requiring
  access to LDAP services.
  """

  use ExUnit.CaseTemplate
  alias Meadow.Accounts.Ldap

  using do
    quote do
      alias Meadow.Accounts.Ldap
      import Meadow.LdapCase
    end
  end

  setup do
    with {:ok, connection} <- Exldap.connect() do
      ["Meadow", "NotMeadow"]
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
        ["Meadow", "NotMeadow"]
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

  def display_names([]), do: []
  def display_names(%Ldap.Entry{} = entry), do: entry.attributes.displayName
  def display_names([entry | entries]), do: [display_names(entry) | display_names(entries)]

  def library_dn(val), do: "CN=#{val},OU=NotMeadow,DC=library,DC=northwestern,DC=edu"
  def meadow_dn(val), do: "CN=#{val},OU=Meadow,DC=library,DC=northwestern,DC=edu"

  def create_ldap_group(group) do
    with {:ok, connection} <- Exldap.connect(),
         group_dn <- library_dn(group) |> to_charlist() do
      attributes = [
        {'objectClass', ['group', 'top']},
        {'groupType', ['4']},
        {'displayName', ["Group #{group}" |> to_charlist()]}
      ]

      case :eldap.add(connection, group_dn, attributes) do
        :ok -> to_string(group_dn)
        {:error, :entryAlreadyExists} -> to_string(group_dn)
        other -> other
      end
    end
  end

  def create_ldap_user(username) do
    with {:ok, connection} <- Exldap.connect(),
         user_dn <- library_dn(username) |> to_charlist() do
      attributes = [
        {'objectClass', ['user', 'person', 'organizationalPerson', 'top']},
        {'displayName', ["User #{username}" |> to_charlist()]},
        {'mail', ["#{username}@library.northwestern.edu" |> to_charlist()]},
        {'cn', [to_charlist(username)]},
        {'sn', ['User']}
      ]

      case :eldap.add(connection, user_dn, attributes) do
        :ok -> to_string(user_dn)
        {:error, :entryAlreadyExists} -> to_string(user_dn)
        other -> other
      end
    end
  end
end
