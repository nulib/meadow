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
      Exldap.Update.add(
        connection,
        "OU=#{ou},DC=library,DC=northwestern,DC=edu",
        %{objectClass: ["organizationalUnit", "top"], ou: ou, name: ou}
      )
    end
  end

  def destroy_ou(ou) do
    with {:ok, connection} <- Exldap.connect(),
         base <- "OU=#{ou},DC=library,DC=northwestern,DC=edu" do
      Exldap.Update.delete(connection, base)
    end
  end

  def empty_ou(ou) do
    with {:ok, connection} <- Exldap.connect(),
         base <- "OU=#{ou},DC=library,DC=northwestern,DC=edu" do
      {:ok, children} =
        Exldap.search(connection,
          base: base,
          scope: :wholeSubtree,
          filter:
            Exldap.with_and([
              Exldap.negate(Exldap.equalityMatch("distinguishedName", base)),
              Exldap.equalityMatch("objectClass", "top")
            ])
        )

      children
      |> Enum.each(fn leaf ->
        Exldap.Update.delete(connection, leaf.object_name)
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
         group_dn <- library_dn(group) do
      attributes = %{
        objectClass: ["group", "top"],
        groupType: 4,
        displayName: "Group #{group}"
      }

      case Exldap.Update.add(connection, group_dn, attributes) do
        :ok -> group_dn
        {:error, :entryAlreadyExists} -> group_dn
        other -> other
      end
    end
  end

  def create_ldap_user(username) do
    with {:ok, connection} <- Exldap.connect(),
         user_dn <- library_dn(username) do
      attributes = %{
        objectClass: ["user", "person", "organizationalPerson", "top"],
        displayName: "User #{username}",
        mail: "#{username}@library.northwestern.edu",
        cn: username,
        sn: "User",
        uid: username
      }

      case Exldap.Update.add(connection, user_dn, attributes) do
        :ok -> to_string(user_dn)
        {:error, :entryAlreadyExists} -> to_string(user_dn)
        other -> other
      end

      user_dn
    end
  end
end
