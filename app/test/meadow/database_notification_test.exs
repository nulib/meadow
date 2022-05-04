defmodule Meadow.DatabaseNotificationTest do
  alias Ecto.Adapters.SQL
  alias Meadow.DatabaseNotification
  use Meadow.UnsandboxedDataCase, async: false

  @migration_version 20_991_120_154_501

  defmodule NotificationTestMigration do
    use Ecto.Migration
    import DatabaseNotification

    @table :notify_test

    def up do
      create table(@table) do
        add(:data, :string)
      end

      create_notification_trigger(@table, :all)
    end

    def down do
      drop_notification_trigger(@table)
      drop(table(@table))
    end
  end

  defmodule NotificationTestListener do
    use DatabaseNotification, tables: [:notify_test]

    @impl true
    def handle_notification(:notify_test, op, key, listener) do
      send(listener, {op, key})
      {:noreply, listener}
    end
  end

  setup %{repo: repo} do
    Ecto.Migrator.up(repo, @migration_version, NotificationTestMigration)
    start_supervised!({NotificationTestListener, self()})

    on_exit(fn ->
      Ecto.Migrator.down(repo, @migration_version, NotificationTestMigration)
    end)

    sql = "INSERT INTO notify_test (data) VALUES ('initial value') RETURNING id"

    [[uuid]] =
      repo
      |> SQL.query!(sql)
      |> Map.get(:rows)

    {:ok, record_id} = Ecto.UUID.load(uuid)
    {:ok, %{record_id: record_id, repo: repo}}
  end

  describe "insert" do
    test "insert notification", %{record_id: record_id} do
      assert_receive({:insert, %{id: ^record_id}})
      refute_receive({:update, _})
      refute_receive({:delete, _})
    end
  end

  describe "update" do
    setup %{repo: repo} do
      assert_receive({:insert, _})
      SQL.query!(repo, "UPDATE notify_test SET data = 'updated value'")
      :ok
    end

    test "update notification", %{record_id: record_id} do
      refute_receive({:insert, _})
      assert_receive({:update, %{id: ^record_id}})
      refute_receive({:delete, _})
    end
  end

  describe "delete" do
    setup %{repo: repo} do
      assert_receive({:insert, _})
      SQL.query!(repo, "DELETE FROM notify_test")
      :ok
    end

    test "delete notification", %{record_id: record_id} do
      refute_receive({:insert, _})
      refute_receive({:update, _})
      assert_receive({:delete, %{id: ^record_id}})
    end
  end
end
