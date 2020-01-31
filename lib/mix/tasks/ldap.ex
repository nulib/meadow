defmodule Mix.Tasks.Meadow.Ldap do
  defmodule Setup do
    @moduledoc """
    Seed Ldap Entries for Dev environment
    """
    require Logger

    @organizational_units [
      "OU=Meadow,DC=library,DC=northwestern,DC=edu",
      "OU=DevUsers,DC=library,DC=northwestern,DC=edu"
    ]

    @usernames [
      "ksd927",
      "mbk836",
      "bmq449",
      "aja0137"
    ]

    @groups [
      "CN=Administrators,OU=Meadow,DC=library,DC=northwestern,DC=edu",
      "CN=Managers,OU=Meadow,DC=library,DC=northwestern,DC=edu",
      "CN=Editors,OU=Meadow,DC=library,DC=northwestern,DC=edu",
      "CN=Users,OU=Meadow,DC=library,DC=northwestern,DC=edu",
      "CN=MeadowUsers,OU=DevUsers,DC=library,DC=northwestern,DC=edu"
    ]

    def run(_) do
      with {:ok, connection} <- Exldap.connect() do
        @organizational_units
        |> Enum.each(fn org ->
          rdn =
            org
            |> find_rdn

          add_entry(connection, org, ou_attributes(rdn))
        end)
      end

      with {:ok, connection} <- Exldap.connect() do
        @groups
        |> Enum.each(fn group_dn ->
          add_entry(connection, group_dn, group_attributes(find_rdn(group_dn)))
        end)
      end

      with {:ok, connection} <- Exldap.connect() do
        @usernames
        |> Enum.each(fn username ->
          user_dn = "CN=#{username},OU=DevUsers,DC=library,DC=northwestern,DC=edu"

          add_entry(connection, user_dn, people_attributes(username))

          group_dn = "CN=MeadowUsers,OU=DevUsers,DC=library,DC=northwestern,DC=edu"
          add_membership(connection, group_dn, user_dn)
        end)

        add_entry(
          connection,
          "CN=auh7250,OU=DevUsers,DC=library,DC=northwestern,DC=edu",
          people_attributes("auh7250")
        )

        add_membership(
          connection,
          "CN=Managers,OU=Meadow,DC=library,DC=northwestern,DC=edu",
          "CN=aja0137,OU=DevUsers,DC=library,DC=northwestern,DC=edu"
        )

        add_membership(
          connection,
          "CN=Users,OU=Meadow,DC=library,DC=northwestern,DC=edu",
          "CN=MeadowUsers,OU=DevUsers,DC=library,DC=northwestern,DC=edu"
        )
      end
    end

    defp add_entry(connection, entry, attributes) do
      case Exldap.Update.add(connection, entry, attributes) do
        :ok ->
          Logger.info("Created LDAP Entry: #{entry}")

        {:error, :entryAlreadyExists} ->
          Logger.info("LDAP Entry #{entry} already exists")

        other ->
          Logger.warn("Unexpected response while creating #{entry}: #{inspect(other)}")
      end
    end

    defp add_membership(connection, parent_dn, child_dn) do
      case Exldap.Update.modify(connection, parent_dn, {:add, :member, child_dn}) do
        :ok ->
          Logger.info("Added LDAP membership for: #{child_dn} to #{parent_dn}")

        {:error, :entryAlreadyExists} ->
          Logger.info("LDAP Entry #{child_dn} is already member of #{parent_dn}")

        other ->
          Logger.warn(
            "Unexpected response while creating membership for  #{child_dn} in #{parent_dn}: #{
              inspect(other)
            }"
          )
      end
    end

    defp ou_attributes(rdn) do
      %{
        objectClass: ["organizationalUnit", "top"],
        ou: rdn,
        name: rdn
      }
    end

    defp group_attributes(rdn) do
      %{
        objectClass: ["group", "top"],
        groupType: 4,
        cn: rdn,
        description: rdn
      }
    end

    defp people_attributes(username) do
      %{
        objectClass: ["user", "person", "organizationalPerson", "top"],
        sn: username,
        uid: username,
        mail: "#{username}@library.northwestern.edu",
        displayName: username
      }
    end

    defp find_rdn(org) do
      org
      |> String.split(",")
      |> Enum.find_value(fn x ->
        case String.split(x, "=", parts: 2) do
          ["OU", val] -> val
          ["CN", val] -> val
          _ -> nil
        end
      end)
    end
  end

  defmodule Teardown do
    @moduledoc """
    Clear out Ldap Entries for Dev environment
    """
    require Logger

    @organizational_units [
      "OU=Meadow,DC=library,DC=northwestern,DC=edu",
      "OU=DevUsers,DC=library,DC=northwestern,DC=edu"
    ]
    def run(_) do
      with {:ok, connection} <- Exldap.connect() do
        @organizational_units
        |> Enum.each(fn org ->
          Logger.info("Destroying OU: #{org}")
          Exldap.Update.delete(connection, org)
        end)
      end
    end
  end
end
