alias Meadow.Config.Secrets

case :ets.info(:secret_cache, :name) do
  :secret_cache -> :ets.delete_all_objects(:secret_cache)
  :undefined -> :ets.new(:secret_cache, [:set, :protected, :named_table])
end

cluster_config =
  Application.get_env(:meadow, Meadow.Search.Cluster)
  |> Keyword.merge(
    url:
      Secrets.get_secret(
        :meadow,
        ["search", "cluster_endpoint"],
        "http://localhost:9200"
      ),
    bulk_page_size: 3,
    bulk_wait_interval: 2,
    embedding_model_id: nil
  )

Application.put_env(:meadow, Meadow.Search.Cluster, cluster_config)

Meadow.Repo.wait_for_connection()

Mix.Task.run("ecto.setup")
Mix.Task.run("meadow.search.setup")

if Meadow.Config.use_localstack?() do
  Mix.Task.run("meadow.pipeline.setup")
  Mix.Task.run("meadow.buckets.create")
end

ExUnit.start(capture_log: true, exclude: [:skip, :validator, manual: true])
Faker.start()
Meadow.Directory.MockServer.prewarm()
Ecto.Adapters.SQL.Sandbox.mode(Meadow.Repo, :manual)
Authoritex.Mock.init()
System.delete_env("MEADOW_PROCESSES")

ExUnit.after_suite(fn _ ->
  Meadow.S3Case.show_cleanup_warnings()
  Mix.Task.run("meadow.search.teardown")
end)
