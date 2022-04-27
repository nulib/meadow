defmodule Meadow.Accounts.Ldap.Entry do
  @moduledoc """
  Simple class/id/name/attributes struct for LDAP entries
  """
  @attributes ["description", "displayName", "mail", "title"]
  @known_types ["group", "user"]
  defstruct type: "unknown", id: nil, name: nil, attributes: %{}

  def new(%Exldap.Entry{} = entry) do
    %__MODULE__{
      type: entry |> extract_type(),
      id: entry.object_name |> to_string(),
      name: entry |> Exldap.get_attribute!("cn"),
      attributes: entry |> extract_attributes()
    }
  end

  def new(connection, dn) do
    case Exldap.search(connection,
           base: dn,
           scope: :baseObject,
           filter: Exldap.equalityMatch("objectClass", "top")
         ) do
      {:ok, [entry]} -> new(entry)
      _ -> %__MODULE__{id: dn}
    end
  end

  defp extract_attributes(%Exldap.Entry{} = entry) do
    @attributes
    |> Enum.map(fn attr -> {String.to_atom(attr), entry |> Exldap.get_attribute!(attr)} end)
    |> Enum.reject(fn {_, v} -> is_nil(v) end)
    |> Enum.into(%{})
  end

  defp extract_type(%Exldap.Entry{} = entry) do
    entry
    |> Exldap.get_attribute!("objectClass")
    |> Enum.find("unknown", fn v -> Enum.member?(@known_types, v) end)
  end
end
