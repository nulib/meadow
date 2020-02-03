defmodule Meadow.LdapCase do
  @moduledoc """
  This module defines the setup for tests requiring
  access to LDAP services.
  """

  use ExUnit.CaseTemplate
  alias Meadow.Accounts.Ldap
  import Meadow.LdapHelpers

  setup do
    on_exit(fn ->
      with {:ok, connection} <- Exldap.connect() do
        empty_tree(connection, "OU=NotMeadow,DC=library,DC=northwestern,DC=edu")
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
         group_dn <- library_dn(group) do
      add_entry(connection, group_dn, group_attributes(group))
      group_dn
    end
  end

  def create_ldap_user(username) do
    with {:ok, connection} <- Exldap.connect(),
         user_dn <- library_dn(username) |> to_charlist() do
      add_entry(connection, user_dn, people_attributes(username))
      user_dn
    end
  end
end
