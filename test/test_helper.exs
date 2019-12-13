ExUnit.configure(formatters: [JUnitFormatter, ExUnit.CLIFormatter])
ExUnit.start(capture_log: true)
Faker.start()
Ecto.Adapters.SQL.Sandbox.mode(Meadow.Repo, :manual)

Mox.defmock(Meadow.ExAwsHttpMock, for: ExAws.Request.HttpClient)
