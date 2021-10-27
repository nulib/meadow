defmodule Meadow.Utils.DependencyTriggers do
  @moduledoc """
  Functions to manage dependency triggers
  """

  use Ecto.Migration

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

  def switch_trigger(trigger_name, table_name, action) do
    ["insert", "update", "delete"]
    |> Enum.each(fn operation ->
      execute("ALTER TABLE #{table_name} #{action} TRIGGER #{trigger_name}_#{operation}")
    end)
  end

  def drop_trigger(trigger_name, table_name, function_name) do
    ["insert", "update", "delete"]
    |> Enum.each(fn operation ->
      execute("DROP TRIGGER IF EXISTS #{trigger_name}_#{operation} ON #{table_name};")
    end)

    execute("DROP FUNCTION IF EXISTS #{function_name};")
  end

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
