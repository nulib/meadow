defmodule Meadow.Accounts.Ldap do
  @moduledoc """
  This module defines functions for creating and managing LDAP/Active Directory
  groups and group membership.
  """

  alias Meadow.Accounts.Schemas.User
  alias Meadow.Config

  @ldap_matching_rule_in_chain "1.2.840.113556.1.4.1941"
  @meadow_base "OU=Meadow,DC=library,DC=northwestern,DC=edu"

  defmodule Entry do
    @moduledoc """
    Simple id/name struct for LDAP entries
    """
    defstruct id: nil, name: nil

    def new(%Exldap.Entry{} = entry) do
      %__MODULE__{
        id: entry.object_name |> to_string(),
        name: entry |> Exldap.get_attribute!("cn")
      }
    end

    def new(connection, dn) do
      case Exldap.search(connection, base: dn, filter: Exldap.equalityMatch("objectClass", "top")) do
        {:ok, [entry]} -> %__MODULE__{id: dn, name: entry |> Exldap.get_attribute!("cn")}
        _ -> %__MODULE__{id: dn, name: nil}
      end
    end
  end

  def connection do
    case Exldap.connect() do
      {:ok, result} -> result
      other -> other
    end
  end

  @doc "Fetch the display name (LDAP commonName) for an entry"
  def display_name(%Entry{} = entry), do: entry.name

  @doc "Fetch the display names (LDAP commonName) for a list of entries"
  def display_names([]), do: []
  def display_names([entry | entries]), do: [display_name(entry) | display_names(entries)]

  @doc "Fetch the unique identifier (LDAP distinguishedName) for a user"
  def user_dn(%Entry{} = user), do: user.id
  def user_dn(%User{username: username}), do: user_dn(username)

  def user_dn(username) do
    with {:ok, results} <- connection() |> Exldap.search_field("cn", username) do
      case results do
        [] ->
          nil

        _ ->
          results
          |> List.first()
          |> Map.get(:object_name)
          |> to_string()
      end
    end
  end

  @doc "List all group names and DNs under the @meadow_base DN"
  def list_groups do
    {:ok, meadow_groups} =
      connection()
      |> Exldap.search_with_filter(
        @meadow_base,
        Exldap.equalityMatch("objectClass", "group")
      )

    meadow_groups
    |> Enum.map(&Entry.new/1)
  end

  @doc "List the members of a given group"
  def list_group_members(group) do
    with conn <- connection() do
      case Exldap.search(conn, base: @meadow_base, filter: Exldap.equalityMatch("cn", group)) do
        {:ok, [entry]} -> extract_members(conn, entry)
        other -> other
      end
    end
  end

  @doc "List the groups a given user belongs to"
  def list_user_groups(user) do
    {:ok, results} =
      connection()
      |> Exldap.search_with_filter(
        @meadow_base,
        Exldap.with_and([
          Exldap.equalityMatch("objectClass", "group"),
          filter_for(user_dn(user))
        ])
      )

    results
    |> Enum.map(&Entry.new/1)
  end

  @doc "Create a group under the @meadow_base DN"
  def create_group(group) do
    with {:ok, connection} <- Exldap.connect(),
         group_dn <- "CN=#{group},#{@meadow_base}" |> to_charlist() do
      attributes = [
        {'objectClass', ['group']},
        {'objectClass', ['top']},
        {'groupType', ['4']},
        {'cn', [group]},
        {'description', [group]}
      ]

      case :eldap.add(connection, group_dn, attributes) do
        :ok ->
          {:ok, Entry.new(connection, group_dn)}

        {:error, :entryAlreadyExists} ->
          {:exists, Entry.new(connection, group_dn)}

        other ->
          other
      end
    end
  end

  @doc "Add a user to a group"
  def add_user(user, group) do
    with user_dn <- user_dn(user),
         group_dn <- "CN=#{group},#{@meadow_base}" |> to_charlist(),
         operation <- :eldap.mod_add('member', [to_charlist(user_dn)]) do
      case modify_entry(group_dn, operation) do
        {:ok, _} -> :ok
        {:exists, _} -> :exists
        other -> other
      end
    end
  end

  @doc "Remove a user from a group"
  def remove_user(user, group) do
    with user_dn <- user_dn(user),
         group_dn <- "CN=#{group},#{@meadow_base}" |> to_charlist(),
         operation <- :eldap.mod_delete('member', [to_charlist(user_dn)]) do
      case modify_entry(group_dn, operation) do
        {:ok, _} -> :ok
        other -> other
      end
    end
  end

  defp extract_members(connection, %Exldap.Entry{} = group) do
    group
    |> Exldap.get_attribute!("member")
    |> ensure_list()
    |> Enum.map(fn dn -> Entry.new(connection, dn) end)
  end

  defp ensure_list(x) when is_list(x), do: x
  defp ensure_list(x), do: [x]

  defp modify_entry(dn, operation) do
    case :eldap.modify(connection(), dn, [operation]) do
      :ok -> {:ok, to_string(dn)}
      {:error, :entryAlreadyExists} -> {:exists, to_string(dn)}
      other -> other
    end
  end

  defp filter_for(dn) do
    case Config.ldap_nested_groups?() do
      true ->
        Exldap.extensibleMatch(dn,
          type: "member",
          matchingRule: @ldap_matching_rule_in_chain
        )

      _ ->
        Exldap.equalityMatch("member", dn)
    end
  end
end
