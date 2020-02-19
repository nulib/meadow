ExUnit.start(capture_log: true)
Faker.start()
Ecto.Adapters.SQL.Sandbox.mode(Meadow.Repo, :manual)
ExUnit.after_suite(fn _ -> Meadow.S3Case.show_cleanup_warnings() end)
