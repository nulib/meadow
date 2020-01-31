defmodule Meadow.Accounts.Ldap do
  @moduledoc """
  This module defines functions for creating and managing LDAP/Active Directory
  groups and group membership.
  """

  alias Meadow.Accounts.Ldap.Entry

  @connect_timeout 1500
  @ldap_matching_rule_in_chain "1.2.840.113556.1.4.1941"
  @meadow_base "OU=Meadow,DC=library,DC=northwestern,DC=edu"

  def connection(force_new \\ false) do
    if force_new, do: Meadow.Cache |> ConCache.delete(:ldap_address)

    settings =
      with config <- Application.get_env(:exldap, :settings) do
        Keyword.put(config, :server, connection_address(config))
      end

    case {Exldap.connect(settings, @connect_timeout), force_new} do
      {{:ok, result}, _} -> result
      {_, false} -> connection(true)
      {other, true} -> other
    end
  end

  @doc "Find a user entry by its common name (NetID)"
  def find_user(cn) do
    case connection()
         |> Exldap.search_with_filter(
           Exldap.with_and([
             Exldap.equalityMatch("cn", cn),
             Exldap.equalityMatch("objectClass", "user")
           ])
         ) do
      {:ok, []} -> nil
      {:ok, [entry]} -> Entry.new(entry)
      {:ok, [_ | _]} -> {:error, :tooManyResults}
      other -> other
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
  def list_group_members(group_dn) do
    with conn <- connection() do
      case Exldap.search(conn,
             base: group_dn,
             scope: :baseObject,
             filter: Exldap.equalityMatch("objectClass", "group")
           ) do
        {:ok, [entry]} -> extract_members(conn, entry)
        other -> other
      end
    end
  end

  @doc "List the groups a given user belongs to"
  def list_user_groups(user_dn) do
    case connection()
         |> Exldap.search_with_filter(
           @meadow_base,
           Exldap.with_and([
             Exldap.equalityMatch("objectClass", "group"),
             Exldap.extensibleMatch(user_dn,
               type: "member",
               matchingRule: @ldap_matching_rule_in_chain
             )
           ])
         ) do
      {:ok, results} -> results |> Enum.map(&Entry.new/1)
      {:error, :noSuchObject} -> []
    end
  end

  @doc "Create a group under the @meadow_base DN"
  def create_group(group_cn) do
    with {:ok, connection} <- Exldap.connect(),
         group_dn <- "CN=#{group_cn},#{@meadow_base}" do
      case Exldap.Update.add(connection, group_dn, %{
             objectClass: ["group", "top"],
             groupType: 4,
             cn: group_cn,
             displayName: "#{group_cn} Group"
           }) do
        :ok ->
          {:ok, Entry.new(connection, group_dn)}

        {:error, :entryAlreadyExists} ->
          {:exists, Entry.new(connection, group_dn)}

        other ->
          other
      end
    end
  end

  @doc "Add a member to a group"
  def add_member(group_dn, member_dn) do
    case Exldap.Update.modify(connection(), group_dn, {:add, :member, member_dn}) do
      {:ok, _} -> :ok
      {:error, :entryAlreadyExists} -> :exists
      other -> other
    end
  end

  @doc "Remove a member from a group"
  def remove_member(group_dn, member_dn) do
    case Exldap.Update.modify(connection(), group_dn, {:delete, :member, member_dn}) do
      {:ok, _} -> :ok
      other -> other
    end
  end

  defp connection_address(config) do
    find_connection = fn tuple ->
      case tuple |> :gen_tcp.connect(config[:port], [:inet]) do
        {:ok, _} -> tuple |> Tuple.to_list() |> Enum.join(".")
        _ -> nil
      end
    end

    Meadow.Cache
    |> ConCache.get_or_store(:ldap_address, fn ->
      {:ok, ldap_addrs} =
        config[:server]
        |> to_charlist()
        |> :inet.getaddrs(:inet, @connect_timeout)

      ldap_addrs
      |> Enum.find_value(find_connection)
    end)
  end

  defp extract_members(connection, %Exldap.Entry{} = group) do
    filter =
      group
      |> Exldap.get_attribute!("member")
      |> ensure_list()
      |> Enum.map(fn dn -> Exldap.equalityMatch("distinguishedName", dn) end)
      |> Exldap.with_or()

    with {:ok, members} <- connection |> Exldap.search_with_filter(filter) do
      members
      |> ensure_list()
      |> Enum.map(fn entry -> Entry.new(entry) end)
    end
  end

  defp ensure_list(x) when is_list(x), do: x
  defp ensure_list(x), do: [x]
end
