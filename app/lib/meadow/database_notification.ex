defmodule Meadow.DatabaseNotification do
  @moduledoc """
  Listen for and handle database notifications.

  Example:

  ```
  defmodule MyDatabaseNotification do
    use Meadow.DatabaseNotification, tables: [:my_table]

    def handle_notification(table, operation, key) do
      # Handle the notification here
      # `table` is the name of the table that _triggered_ the notification,
      #    not necessarily the table _receiving_ the notification.
      # `operation` is `:insert`, `:update`, or `:delete`
      # `key` is a map containing the primary key fields of the row _receiving_
      #    the notification
      # of the changed record.

      :ok
    end
  end
  ```

  Add to the list of workers in `lib/meadow/application/children.ex`:
  ```
  defp workers(nil) do
    [
      MyDatabaseWorker
    ]
  end
  ```

  ## Creating the database notification triggers

  In order for the process to receive change notifications, the database has
  to send them.

  It is currently not possible to have more than one trigger on a table,
  each trigger listening for specific field/column changes.

  So, first see if a database trigger already exists for the table you need
  and confirm that it is listening for changes on :all fields
  (or on the specific field you need).

  Only if the trigger does not exist for the table would you need to create one.

  #{__MODULE__} provides two functions to assist with the creation
  (and destruction) of the necessary Postgres functions and triggers/

  Create a database migration containing the trigger you need.

  ```
  defmodule MyDatabaseNotificationTrigger do
    use Ecto.Migration
    import Meadow.DatabaseNotification

    def up do
      # to be notified of all changes
      create_notification_trigger(:my_table, :all)

      # to be notified of changes to specific fields
      create_notification_trigger(:my_table, ["specific", "fields"])
    end

    def down do
      drop_notification_trigger(:my_table)
    end
  end
  ```
  """

  @type operation :: :insert | :update | :delete
  @callback handle_notification(
              table :: atom(),
              operation :: operation(),
              key :: map(),
              state :: any()
            ) :: any()

  defmacro __using__(args) do
    quote location: :keep, bind_quoted: [tables: Keyword.get(args, :tables, [])] do
      use GenServer
      require Logger

      @behaviour Meadow.DatabaseNotification

      def child_spec(opts) do
        %{
          id: __MODULE__,
          start: {__MODULE__, :start_link, [opts]}
        }
      end

      def start_link(args \\ []) do
        GenServer.start_link(__MODULE__, args, name: __MODULE__)
      end

      @impl GenServer
      def init(initial_state) do
        unquote(tables)
        |> Enum.each(fn table ->
          Logger.info("#{__MODULE__}: Listening for changes to '#{table}'")
          Meadow.Repo.listen("#{table}_changed")
        end)

        {:ok, initial_state}
      end

      tables
      |> Enum.each(fn table ->
        with message <- "#{table}_changed" do
          @impl GenServer
          def handle_info({:notification, _pid, _ref, message, payload}, state) do
            with data <- Jason.decode!(payload, keys: :atoms) do
              state =
                Map.get(data, :ids)
                |> Enum.reduce(state, fn id, new_state ->
                  {:noreply, new_state} =
                    handle_notification(
                      Map.get(data, :source) |> String.to_atom(),
                      Map.get(data, :operation) |> String.downcase() |> String.to_atom(),
                      %{id: id},
                      new_state
                    )

                  new_state
                end)
            end

            {:noreply, state}
          rescue
            exception ->
              Meadow.Error.report(exception, __MODULE__, __STACKTRACE__)
              reraise(exception, __STACKTRACE__)
          end
        end
      end)

      @impl GenServer
      def handle_info({:ssl_closed, _msg}, state), do: {:noreply, state}

      def handle_info({:data, msg}, state) do
        Logger.warning("#{inspect(msg)}")
        {:noreply, state}
      end
    end
  end

  def create_notification_trigger(table, fields),
    do: create_notification_trigger(table, fields, table, "id")

  def create_notification_trigger(table, fields, target, target_field) do
    condition = field_condition(fields)
    function_name = "notify_#{target}_when_#{table}_changes"

    Ecto.Migration.execute("""
      CREATE OR REPLACE FUNCTION #{function_name}()
      RETURNS trigger AS $$
      DECLARE
        ids UUID[];
        id_count INT;
        payload TEXT;
      BEGIN
        CASE TG_OP
          WHEN 'INSERT' THEN
            CREATE TEMPORARY TABLE notifications AS (SELECT DISTINCT #{target_field} AS id FROM new_table);
          WHEN 'UPDATE' THEN
            CREATE TEMPORARY TABLE notifications AS (SELECT DISTINCT new_table.#{target_field} AS id
              FROM new_table
              JOIN old_table
              ON new_table.id = old_table.id
              AND (#{condition}));
          WHEN 'DELETE' THEN
            CREATE TEMPORARY TABLE notifications AS (SELECT DISTINCT #{target_field} AS id FROM old_table);
          END CASE;

        SELECT array_agg(id) INTO ids FROM (SELECT id FROM notifications WHERE id IS NOT NULL LIMIT 100) AS notification_ids;
        SELECT array_length(ids, 1) INTO id_count;

        WHILE (ids IS NOT NULL) AND (id_count > 0) AND NOT (id_count = 1 AND ids[1] IS NULL) LOOP
          SELECT json_build_object('operation', TG_OP, 'source', '#{table}', 'ids', ids)::text INTO payload;
          RAISE NOTICE 'Sending % from % with payload: %', '#{target}_changed', '#{function_name}', payload;
          PERFORM pg_notify('#{target}_changed', payload);
          DELETE FROM notifications WHERE id = ANY(ids);
          SELECT array_agg(id) INTO ids FROM (SELECT id FROM notifications WHERE id IS NOT NULL LIMIT 100) AS notification_ids;
          SELECT array_length(ids, 1) INTO id_count;
        END LOOP;
        DROP TABLE notifications;
        RETURN NULL;
      END;
      $$ LANGUAGE plpgsql;
    """)

    Ecto.Migration.execute("DROP TRIGGER IF EXISTS #{function_name}_insert ON #{table}")

    Ecto.Migration.execute("""
      CREATE TRIGGER #{function_name}_insert
        AFTER INSERT ON #{table}
        REFERENCING NEW TABLE AS new_table
        FOR EACH STATEMENT
        EXECUTE PROCEDURE #{function_name}()
    """)

    Ecto.Migration.execute("DROP TRIGGER IF EXISTS #{function_name}_update ON #{table}")

    Ecto.Migration.execute("""
      CREATE TRIGGER #{function_name}_update
        AFTER UPDATE ON #{table}
        REFERENCING OLD TABLE AS old_table NEW TABLE AS new_table
        FOR EACH STATEMENT
        EXECUTE PROCEDURE #{function_name}()
    """)

    Ecto.Migration.execute("DROP TRIGGER IF EXISTS #{function_name}_delete ON #{table}")

    Ecto.Migration.execute("""
      CREATE TRIGGER #{function_name}_delete
        AFTER DELETE ON #{table}
        REFERENCING OLD TABLE AS old_table
        FOR EACH STATEMENT
        EXECUTE PROCEDURE #{function_name}()
    """)
  end

  def drop_notification_trigger(table), do: drop_notification_trigger(table, table)

  def drop_notification_trigger(table, target) do
    with function_name <- "notify_#{target}_when_#{table}_changes" do
      Ecto.Migration.execute("DROP TRIGGER IF EXISTS #{function_name} ON #{table}")
      Ecto.Migration.execute("DROP TRIGGER IF EXISTS #{function_name}_insert ON #{table}")
      Ecto.Migration.execute("DROP TRIGGER IF EXISTS #{function_name}_update ON #{table}")
      Ecto.Migration.execute("DROP TRIGGER IF EXISTS #{function_name}_delete ON #{table}")
      Ecto.Migration.execute("DROP FUNCTION IF EXISTS #{function_name}")
    end
  end

  def drop_old_notification_trigger(table) do
    Ecto.Migration.execute("DROP TRIGGER IF EXISTS #{table}_changed ON #{table}")
    Ecto.Migration.execute("DROP TRIGGER IF EXISTS #{table}_changed_insert ON #{table}")
    Ecto.Migration.execute("DROP TRIGGER IF EXISTS #{table}_changed_update ON #{table}")
    Ecto.Migration.execute("DROP TRIGGER IF EXISTS #{table}_changed_delete ON #{table}")
    Ecto.Migration.execute("DROP FUNCTION IF EXISTS notify_#{table}_changed")
  end

  defp field_condition(fields, new_old_table_names \\ {"new_table", "old_table"})

  defp field_condition(:all, _), do: "true"

  defp field_condition([], _), do: "true"

  defp field_condition(fields, {new, old}) do
    fields
    |> Enum.flat_map(
      &[
        "(#{new}.#{&1} <> #{old}.#{&1})",
        "(#{new}.#{&1} IS NULL AND #{old}.#{&1} IS NOT NULL)",
        "(#{new}.#{&1} IS NOT NULL AND #{old}.#{&1} IS NULL)"
      ]
    )
    |> Enum.join(" OR ")
  end
end
