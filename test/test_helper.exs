ExUnit.start(capture_log: true)
Faker.start()
Ecto.Adapters.SQL.Sandbox.mode(Meadow.Repo, :manual)

Mox.defmock(Meadow.ExAwsHttpMock, for: ExAws.Request.HttpClient)

["Meadow", "NotMeadow"] |> Enum.each(&Meadow.LdapCase.create_ou/1)

ExUnit.after_suite(fn _ ->
  ["Meadow", "NotMeadow"] |> Enum.each(&Meadow.LdapCase.destroy_ou/1)
end)
