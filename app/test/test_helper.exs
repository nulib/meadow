Hush.resolve!()
Meadow.Repo.wait_for_connection()

Mix.Task.run("ecto.setup")
Mix.Task.run("meadow.search.setup")

unless System.get_env("AWS_DEV_ENVIRONMENT") do
  Mix.Task.run("meadow.pipeline.setup")
  Mix.Task.run("meadow.buckets.create")
  Mix.Task.run("meadow.ldap.teardown", ["test/fixtures/ldap_seed.ldif"])
  Mix.Task.run("meadow.ldap.setup", ["test/fixtures/ldap_seed.ldif"])
end

ExUnit.start(capture_log: true, exclude: [:skip, :validator, manual: true])
Faker.start()
Ecto.Adapters.SQL.Sandbox.mode(Meadow.Repo, :manual)
Authoritex.Mock.init()
ExUnit.after_suite(fn _ -> Meadow.S3Case.show_cleanup_warnings() end)
