defmodule Mix.Tasks.Meadow.Ldap.Setup do
  @moduledoc """
  Create all configured S3 buckets
  """
  require Logger
  @meadow_base "OU=Meadow,DC=library,DC=northwestern,DC=edu"

  def run(_) do
    ou =
      @meadow_base
      |> String.split(",")
      |> Enum.find_value(fn x ->
        case String.split(x, "=", parts: 2) do
          ["OU", val] -> val
          _ -> nil
        end
      end)

    attributes = [
      {'objectClass', ['organizationalUnit']},
      {'objectClass', ['top']},
      {'ou', [to_charlist(ou)]},
      {'name', [to_charlist(ou)]}
    ]

    with {:ok, connection} <- Exldap.connect() do
      case :eldap.add(connection, to_charlist(@meadow_base), attributes) do
        :ok -> Logger.info("Created LDAP Entry: #{@meadow_base}")
        {:error, :entryAlreadyExists} -> Logger.info("LDAP Entry #{@meadow_base} already exists")
        other -> Logger.warn("Unexpected response while creating #{@meadow_base}: #{other}")
      end
    end
  end
end
