defmodule Meadow.Utils.DependencyTriggers do
  @moduledoc """
  Base behavior for dependency triggers
  """

  @doc """
  Given the names of a parent table, child table, list of fields, and the stem of the joining column,
  return the text of the dependency trigger for the child table.
  """
  @callback dependency_trigger(
              parent :: binary(),
              child :: binary(),
              fields :: list(),
              column_name :: binary()
            ) :: binary()

  @doc """
  Given the names of a parent table, child table, and list of fields,
  return the text of the dependency trigger for the parent table.
  """
  @callback parent_trigger(parent :: binary(), child :: binary(), fields :: list()) :: binary()

  @doc """
  Create a trigger on `table_name` that fires `function_name`
  """
  @callback create_trigger(
              trigger_name :: binary(),
              table_name :: binary(),
              function_name :: binary()
            ) :: any()

  @callback switch_trigger(trigger_name :: binary(), table_name :: binary(), action :: binary()) ::
              any()

  @callback drop_trigger(
              trigger_name :: binary(),
              table_name :: binary(),
              function_name :: binary()
            ) :: any()

  defmacro __using__(_) do
    quote do
      @behaviour Meadow.Utils.DependencyTriggers
      use Ecto.Migration

      def create_dependency_trigger(parent, child, fields) do
        create_dependency_trigger(parent, child, fields, parent)
      end

      def create_dependency_trigger(parent, child, fields, column_name) do
        with {function_name, trigger_name} <- object_names(parent, child) do
          dependency_trigger(parent, child, fields, column_name) |> execute()
          create_trigger(trigger_name, parent, function_name)
        end
      end

      def create_parent_trigger(parent, child, fields) do
        with {function_name, trigger_name} <- object_names_for_parent_trigger(parent, child) do
          parent_trigger(parent, child, fields) |> execute()
          create_trigger(trigger_name, child, function_name)
        end
      end

      def disable_dependency_trigger(parent, child) do
        with {_function_name, trigger_name} <- object_names(parent, child) do
          switch_trigger(trigger_name, parent, "DISABLE")
        end
      end

      def enable_dependency_trigger(parent, child) do
        with {_function_name, trigger_name} <- object_names(parent, child) do
          switch_trigger(trigger_name, parent, "ENABLE")
        end
      end

      def disable_parent_trigger(parent, child) do
        with {_function_name, trigger_name} <- object_names_for_parent_trigger(parent, child) do
          switch_trigger(trigger_name, child, "DISABLE")
        end
      end

      def enable_parent_trigger(parent, child) do
        with {_function_name, trigger_name} <- object_names_for_parent_trigger(parent, child) do
          switch_trigger(trigger_name, child, "ENABLE")
        end
      end

      def drop_dependency_trigger(parent, child) do
        with {function_name, trigger_name} <- object_names(parent, child) do
          drop_trigger(trigger_name, parent, function_name)
        end
      end

      def drop_parent_trigger(parent, child) do
        with {function_name, trigger_name} <- object_names_for_parent_trigger(parent, child) do
          drop_trigger(trigger_name, child, function_name)
        end
      end

      defp object_names(parent, child) do
        {
          "reindex_#{child}_when_#{parent}_changes",
          "#{parent}_#{child}_reindex"
        }
      end

      defp object_names_for_parent_trigger(parent, child) do
        {
          "reindex_#{parent}_when_#{child}_changes",
          "#{child}_#{parent}_reindex"
        }
      end
    end
  end
end

defmodule Meadow.Utils.DependencyTriggers.ForEachStatement do
  @moduledoc """
  Statement-level implementation for Meadow.Utils.DependencyTriggers
  """

  use Meadow.Utils.DependencyTriggers

  @impl true
  def dependency_trigger(parent, child, fields, column_name) do
    with {function_name, _trigger_name} <- object_names(parent, child),
         condition <- match_condition(fields) do
      """
      CREATE OR REPLACE FUNCTION #{function_name}()
        RETURNS trigger AS $$
      BEGIN
        CASE TG_OP
          WHEN 'INSERT' THEN
            IF EXISTS (SELECT FROM new_table) THEN
              UPDATE #{child} SET updated_at = NOW()
              WHERE #{Inflex.singularize(column_name)}_id = ANY (SELECT DISTINCT new_table.id FROM new_table);
            END IF;
          WHEN 'UPDATE' THEN
            IF EXISTS (SELECT FROM new_table) THEN
              UPDATE #{child} SET updated_at = NOW()
              WHERE #{Inflex.singularize(column_name)}_id = ANY (
                SELECT DISTINCT new_table.id
                FROM new_table JOIN old_table ON new_table.id = old_table.id AND (#{condition})
              );
            END IF;
          WHEN 'DELETE' THEN
            IF EXISTS (SELECT FROM old_table) THEN
              UPDATE #{child} SET updated_at = NOW()
              WHERE #{Inflex.singularize(column_name)}_id = ANY (SELECT DISTINCT old_table.id FROM old_table);
            END IF;
        END CASE;
        RETURN NULL;
      END;
      $$ LANGUAGE plpgsql
      """
    end
  end

  @impl true
  def parent_trigger(parent, child, fields) do
    with {function_name, _trigger_name} <- object_names_for_parent_trigger(parent, child),
         condition <- match_condition(fields) do
      """
      CREATE OR REPLACE FUNCTION #{function_name}()
        RETURNS trigger AS $$
      BEGIN
        CASE TG_OP
          WHEN 'INSERT' THEN
            IF EXISTS (SELECT FROM new_table) THEN
              UPDATE #{parent} SET updated_at = NOW()
              WHERE id = ANY (SELECT DISTINCT new_table.id FROM new_table);
            END IF;
          WHEN 'UPDATE' THEN
            IF EXISTS (SELECT FROM new_table) THEN
              UPDATE #{parent} SET updated_at = NOW()
              WHERE id = ANY (
                SELECT DISTINCT new_table.#{Inflex.singularize(parent)}_id
                FROM new_table JOIN old_table ON new_table.id = old_table.id AND (#{condition})
              );
            END IF;
          WHEN 'DELETE' THEN
            IF EXISTS (SELECT FROM old_table) THEN
              UPDATE #{parent} SET updated_at = NOW()
              WHERE id = ANY (SELECT DISTINCT old_table.id FROM old_table);
            END IF;
        END CASE;
        RETURN NULL;
      END;
      $$ LANGUAGE plpgsql
      """
    end
  end

  defp match_condition(fields) do
    fields
    |> Enum.flat_map(
      &[
        "(new_table.#{&1} <> old_table.#{&1})",
        "(new_table.#{&1} IS NULL AND old_table.#{&1} IS NOT NULL)",
        "(new_table.#{&1} IS NOT NULL AND old_table.#{&1} IS NULL)"
      ]
    )
    |> Enum.join(" OR ")
  end

  @impl true
  def create_trigger(trigger_name, table_name, function_name) do
    execute("""
    CREATE TRIGGER #{trigger_name}_insert
      AFTER INSERT ON #{table_name}
      REFERENCING NEW TABLE AS new_table
      FOR EACH STATEMENT
      EXECUTE PROCEDURE #{function_name}();
    """)

    execute("""
    CREATE TRIGGER #{trigger_name}_update
      AFTER UPDATE ON #{table_name}
      REFERENCING OLD TABLE AS old_table NEW TABLE AS new_table
      FOR EACH STATEMENT
      EXECUTE PROCEDURE #{function_name}();
    """)

    execute("""
    CREATE TRIGGER #{trigger_name}_delete
      AFTER DELETE ON #{table_name}
      REFERENCING OLD TABLE AS old_table
      FOR EACH STATEMENT
      EXECUTE PROCEDURE #{function_name}();
    """)
  end

  @impl true
  def switch_trigger(trigger_name, table_name, action) do
    ["insert", "update", "delete"]
    |> Enum.each(fn operation ->
      execute("ALTER TABLE #{table_name} #{action} TRIGGER #{trigger_name}_#{operation}")
    end)
  end

  @impl true
  def drop_trigger(trigger_name, table_name, function_name) do
    ["insert", "update", "delete"]
    |> Enum.each(fn operation ->
      execute("DROP TRIGGER IF EXISTS #{trigger_name}_#{operation} ON #{table_name};")
    end)

    execute("DROP FUNCTION IF EXISTS #{function_name};")
  end
end

defmodule Meadow.Utils.DependencyTriggers.ForEachRow do
  @moduledoc """
  Row-level implementation for Meadow.Utils.DependencyTriggers
  """

  use Meadow.Utils.DependencyTriggers

  @impl true
  def dependency_trigger(parent, child, fields, column_name) do
    with {function_name, _trigger_name} <- object_names(parent, child),
         condition <- match_condition(fields) do
      """
      CREATE OR REPLACE FUNCTION #{function_name}()
        RETURNS trigger AS $$
      BEGIN
        IF #{condition} THEN
          UPDATE #{child} SET updated_at = NOW() WHERE #{Inflex.singularize(column_name)}_id = NEW.id;
        END IF;
        RETURN NEW;
      END;
      $$ LANGUAGE plpgsql
      """
    end
  end

  @impl true
  def parent_trigger(parent, child, fields) do
    with {function_name, _trigger_name} <- object_names_for_parent_trigger(parent, child),
         condition <- match_condition(fields) do
      """
      CREATE OR REPLACE FUNCTION #{function_name}()
        RETURNS trigger AS $$
      BEGIN
        IF #{condition} THEN
          UPDATE #{parent} SET updated_at = NOW() WHERE id = NEW.#{Inflex.singularize(parent)}_id;
        END IF;
        RETURN NEW;
      END;
      $$ LANGUAGE plpgsql
      """
    end
  end

  defp match_condition(fields) do
    fields
    |> Enum.flat_map(
      &[
        "(NEW.#{&1} <> OLD.#{&1})",
        "(NEW.#{&1} IS NULL AND OLD.#{&1} IS NOT NULL)",
        "(NEW.#{&1} IS NOT NULL AND OLD.#{&1} IS NULL)"
      ]
    )
    |> Enum.join(" OR ")
  end

  @impl true
  def create_trigger(trigger_name, table_name, function_name) do
    execute("""
    CREATE TRIGGER #{trigger_name}
      AFTER UPDATE
      ON #{table_name}
      FOR EACH ROW
      EXECUTE PROCEDURE #{function_name}()
    """)
  end

  @impl true
  def switch_trigger(trigger_name, table_name, action) do
    execute("ALTER TABLE #{table_name} #{action} TRIGGER #{trigger_name}")
  end

  @impl true
  def drop_trigger(trigger_name, table_name, function_name) do
    execute("DROP TRIGGER IF EXISTS #{trigger_name} ON #{table_name};")
    execute("DROP FUNCTION IF EXISTS #{function_name};")
  end
end
