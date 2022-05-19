defmodule Meadow.Accounts.Ldap do
  @moduledoc """
  This module defines functions for creating and managing LDAP/Active Directory
  groups and group membership.
  """

  require Logger

  alias Meadow.Accounts.Ldap.Entry

  @connect_timeout 1500
  @retries 3
  @ldap_matching_rule_in_chain "1.2.840.113556.1.4.1941"

  def connection(force_new \\ false) do
    if force_new, do: Meadow.Cache |> Cachex.del(:ldap_address)

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
    find_user_func = fn ->
      connection()
      |> Exldap.search_with_filter(
        Exldap.with_and([
          Exldap.equalityMatch("cn", cn),
          Exldap.equalityMatch("objectClass", "user")
        ])
      )
    end

    case with_retry(find_user_func) do
      {:ok, []} ->
        nil

      {:ok, [entry]} ->
        Entry.new(entry)

      {:ok, [_ | _]} ->
        {:error, :tooManyResults}

      {:error, error} ->
        Logger.error("Error retrieving user #{cn} from LDAP after #{@retries} retries")
        Logger.error("#{inspect(error)}")
        nil
    end
  end

  @doc "List all group names and DNs under the Meadow base DN"
  def list_groups do
    list_groups_func = fn ->
      connection()
      |> Exldap.search_with_filter(
        base_dn(),
        Exldap.equalityMatch("objectClass", "group")
      )
    end

    case with_retry(list_groups_func) do
      {:ok, meadow_groups} ->
        Enum.map(meadow_groups, &Entry.new/1)

      {:error, error} ->
        Logger.error("Error retrieving Meadow groups from LDAP after #{@retries} retries")
        Logger.error("#{inspect(error)}")
        []
    end
  end

  @doc "List the members of a given group"
  def list_group_members(group_dn) do
    list_group_members_func = fn ->
      with conn <- connection() do
        case Exldap.search(conn,
               base: group_dn,
               scope: :eldap.baseObject(),
               filter: Exldap.equalityMatch("objectClass", "group")
             ) do
          {:ok, [entry]} -> extract_members(conn, entry)
          {:error, :noSuchObject} -> []
          other -> other
        end
      end
    end

    case with_retry(list_group_members_func) do
      {:error, error} ->
        Logger.error("Error retrieving #{group_dn} members after #{@retries} retries")
        Logger.error("#{inspect(error)}")
        []

      other ->
        other
    end
  end

  @doc "List the groups a given user belongs to"
  def list_user_groups(user_dn) do
    list_user_groups_func = fn ->
      case connection()
           |> Exldap.search_with_filter(
             base_dn(),
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

    case with_retry(list_user_groups_func) do
      {:error, error} ->
        Logger.error("Error retrieving #{user_dn} groups after #{@retries} retries")
        Logger.error("#{inspect(error)}")
        []

      other ->
        other
    end
  end

  @doc "Create a group under the Meadow base DN"
  def create_group(group_cn) do
    create_group_func = fn ->
      with {:ok, connection} <- Exldap.connect(),
           group_dn <- "CN=#{group_cn},#{base_dn()}" do
        attributes =
          map_to_attributes(%{
            objectClass: ["group", "top"],
            groupType: 4,
            cn: group_cn,
            displayName: "#{group_cn} Group"
          })

        case :eldap.add(connection, to_charlist(group_dn), attributes) do
          :ok ->
            {:ok, Entry.new(connection, group_dn)}

          {:error, :entryAlreadyExists} ->
            {:exists, Entry.new(connection, group_dn)}

          other ->
            other
        end
      end
    end

    case with_retry(create_group_func) do
      {:error, error} ->
        Logger.error("Unable to create group #{group_cn}: #{inspect(error)}")
        {:error, error}

      other ->
        other
    end
  end

  @doc "Add a member to a group"
  def add_member(group_dn, member_dn) do
    with operation <- :eldap.mod_add('member', [to_charlist(member_dn)]) do
      case modify_entry(group_dn, operation) do
        {:ok, _} -> :ok
        {:exists, _} -> :exists
        other -> other
      end
    end
  end

  @doc "Remove a member from a group"
  def remove_member(group_dn, member_dn) do
    with operation <- :eldap.mod_delete('member', [to_charlist(member_dn)]) do
      case modify_entry(group_dn, operation) do
        {:ok, _} -> :ok
        other -> other
      end
    end
  end

  defp map_to_attributes(map) do
    map
    |> Enum.map(fn {key, value} ->
      {
        to_charlist(key),
        value |> ensure_list() |> Enum.map(fn v -> v |> to_string() |> to_charlist() end)
      }
    end)
  end

  defp base_dn do
    with ldap_base <- Application.get_env(:exldap, :settings) |> Keyword.get(:base) do
      ["OU=Meadow", ",", ldap_base] |> IO.iodata_to_binary()
    end
  end

  defp connection_address(config) do
    find_connection = fn tuple ->
      case tuple |> :gen_tcp.connect(config[:port], [:inet]) do
        {:ok, _} -> tuple |> Tuple.to_list() |> Enum.join(".")
        _ -> nil
      end
    end

    cache_response =
      Meadow.Cache
      |> Cachex.fetch(:ldap_address, fn ->
        {:ok, ldap_addrs} =
          config[:server]
          |> to_charlist()
          |> :inet.getaddrs(:inet, @connect_timeout)

        {:commit, ldap_addrs |> Enum.find_value(find_connection)}
      end)

    case cache_response do
      {:ok, val} -> val
      {:commit, val} -> val
      other -> {:error, other}
    end
  end

  defp extract_members(connection, %Exldap.Entry{} = group) do
    filter =
      group
      |> Exldap.get_attribute!("member")
      |> ensure_list()
      |> Enum.map(fn dn -> Exldap.equalityMatch("distinguishedName", dn) end)
      |> Exldap.with_or()

    case with_retry(fn -> connection |> Exldap.search_with_filter(filter) end) do
      {:ok, members} ->
        members
        |> ensure_list()
        |> Enum.map(fn entry -> Entry.new(entry) end)

      {:error, error} ->
        Logger.error("Unable to extract members from #{group.object_name}: #{inspect(error)}")
        {:error, error}
    end
  end

  defp ensure_list(x) when is_list(x), do: x
  defp ensure_list(x) when is_nil(x), do: []
  defp ensure_list(x), do: [x]

  defp modify_entry(dn, operation) do
    modify_entry_func = fn ->
      case :eldap.modify(connection(), to_charlist(dn), [operation]) do
        :ok -> {:ok, dn}
        {:error, :entryAlreadyExists} -> {:exists, dn}
        other -> other
      end
    end

    case with_retry(modify_entry_func) do
      {:error, error} ->
        Logger.error("Unable to modify #{dn}: #{inspect(error)}")
        nil

      other ->
        other
    end
  end

  defp with_retry(func, remaining_tries \\ @retries, last_response \\ nil)

  defp with_retry(_, 0, last_response), do: last_response

  defp with_retry(func, remaining_tries, _) do
    with response <- func.() do
      case response do
        {:error, _} -> with_retry(func, remaining_tries - 1, response)
        other -> other
      end
    end
  end
end
