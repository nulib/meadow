defmodule Meadow.DatabaseNotification do
  @moduledoc """
  Listen for and handle database notifications.

  Example:

  ```
  defmodule MyDatabaseNotification do
    use Meadow.DatabaseNotification, tables: [:my_table]

    def handle_notification(table, operation, key) do
      # Handle the notification here
      # `table` is the name of the table (as an atom)
      # `operation` is `:insert`, `:update`, or `:delete`
      # `key` is a map containing the primary key fields
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
  to send them. #{__MODULE__} provides two functions to assist with the creation
  (and destruction) of the necessary Postgres functions and triggers:

  ```
  defmodule MyDatabaseNotificationTrigger do
    use Ecto.Migration
    import Meadow.DatabaseNotification

    def up do
      create_notification_trigger(:my_table)
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
              {:noreply, state} =
                handle_notification(
                  unquote(table),
                  Map.get(data, :operation) |> String.downcase() |> String.to_atom(),
                  Map.get(data, :key, nil),
                  state
                )
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
    end
  end

  def create_notification_trigger(table) do
    Ecto.Migration.execute("""
      CREATE OR REPLACE FUNCTION notify_#{table}_changed()
      RETURNS trigger AS $$
      DECLARE
        changed JSONB;
        key_field TEXT;
        key JSONB := jsonb_object('{}');
        payload TEXT;
      BEGIN
        IF TG_OP IN ('INSERT', 'UPDATE') THEN
          changed = row_to_json(NEW)::JSONB;
        ELSE
          changed = row_to_json(OLD)::JSONB;
        END IF;

        -- Build the key dynamically based on the primary key
        -- of the table. This will usually be {"id": record.id}
        -- but this allows for notifications on tables with
        -- compound keys.

        FOR key_field IN
          SELECT c.column_name
          FROM information_schema.key_column_usage AS c
          LEFT JOIN information_schema.table_constraints AS t
          ON t.constraint_name = c.constraint_name
          WHERE t.table_name = '#{table}' AND t.constraint_type = 'PRIMARY KEY'
          ORDER BY c.ordinal_position
        LOOP
          key = jsonb_set(key, ('{'||key_field||'}')::text[], changed->key_field);
        END LOOP;

        SELECT json_build_object('operation', TG_OP, 'key', key)::text INTO payload;
        PERFORM pg_notify('#{table}_changed', payload);

        RETURN NEW;
      END;
      $$ LANGUAGE plpgsql;
    """)

    Ecto.Migration.execute("""
      CREATE TRIGGER #{table}_changed
        AFTER INSERT OR UPDATE OR DELETE ON #{table}
        FOR EACH ROW
        EXECUTE PROCEDURE notify_#{table}_changed()
    """)
  end

  def drop_notification_trigger(table) do
    Ecto.Migration.execute("DROP TRIGGER IF EXISTS #{table}_changed ON #{table}")
    Ecto.Migration.execute("DROP FUNCTION IF EXISTS notify_#{table}_changed")
  end
end
