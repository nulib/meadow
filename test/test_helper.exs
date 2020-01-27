ExUnit.start(capture_log: true)
Faker.start()
Ecto.Adapters.SQL.Sandbox.mode(Meadow.Repo, :manual)

Mox.defmock(Meadow.ExAwsHttpMock, for: ExAws.Request.HttpClient)

with {:ok, connection} <- Exldap.connect() do
  ["Meadow", "NotMeadow"]
  |> Enum.each(fn ou ->
    :ok ==
      Meadow.LdapHelpers.add_entry(
        connection,
        "OU=#{ou},DC=library,DC=northwestern,DC=edu",
        Meadow.LdapHelpers.ou_attributes(ou)
      )
  end)

  ~w[Administrators Managers Editors Users]
  |> Enum.each(fn group ->
    Meadow.LdapHelpers.add_entry(
      connection,
      "CN=#{group},OU=Meadow,DC=library,DC=northwestern,DC=edu",
      Meadow.LdapHelpers.group_attributes(group)
    )
  end)
end

ExUnit.after_suite(fn _ ->
  with {:ok, connection} <- Exldap.connect() do
    ["Meadow", "NotMeadow"]
    |> Enum.each(fn ou ->
      :ok ==
        Meadow.LdapHelpers.destroy_entry(connection, "OU=#{ou},DC=library,DC=northwestern,DC=edu")
    end)
  end
end)
