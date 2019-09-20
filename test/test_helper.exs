ExUnit.start(capture_log: true)
Ecto.Adapters.SQL.Sandbox.mode(Meadow.Repo, :manual)

Mox.defmock(Meadow.ExAwsHttpMock, for: ExAws.Request.HttpClient)
