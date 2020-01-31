defmodule Meadow.LdapCase do
  @moduledoc """
  This module defines the setup for tests requiring
  access to LDAP services.
  """

  use ExUnit.CaseTemplate
  alias Meadow.Accounts.Ldap

  setup do
    on_exit(fn ->
      ["Meadow", "NotMeadow"]
      |> Enum.each(&empty_ou/1)
    end)

    :ok
  end

  def create_ou(ou) do
    with {:ok, connection} <- Exldap.connect() do
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
    end
  end

  def destroy_ou(ou) do
    with {:ok, connection} <- Exldap.connect(),
         base <- "OU=#{ou},DC=library,DC=northwestern,DC=edu" do
      :eldap.delete(connection, to_charlist(base))
    end
  end

  def empty_ou(ou) do
    with {:ok, connection} <- Exldap.connect(),
         base <- "OU=#{ou},DC=library,DC=northwestern,DC=edu" do
      {:ok, children} =
        Exldap.search(connection,
          base: base,
          scope: :eldap.wholeSubtree(),
          filter:
            Exldap.with_and([
              Exldap.negate(Exldap.equalityMatch("distinguishedName", base)),
              Exldap.equalityMatch("objectClass", "top")
            ])
        )

      children
      |> Enum.each(fn leaf ->
        :eldap.delete(connection, leaf.object_name)
      end)
    end
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

      group_dn
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
        {'sn', ['User']},
        {'uid', [to_charlist(username)]}
      ]

      case :eldap.add(connection, user_dn, attributes) do
        :ok -> to_string(user_dn)
        {:error, :entryAlreadyExists} -> to_string(user_dn)
        other -> other
      end

      user_dn
    end
  end
end
