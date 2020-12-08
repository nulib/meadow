defmodule Meadow.Repo.Migrations.CreateDependencyTriggers do
  use Ecto.Migration

  def up do
    create_dependency_trigger(:ingest_sheets, :works, [:title])
    create_dependency_trigger(:collections, :works, [:title])
    create_dependency_trigger(:works, :file_sets, [:published, :visibility])

    create_dependency_trigger(
      :works,
      :collections,
      [:representative_file_set_id],
      :representative_work
    )

    create_parent_trigger(:works, :file_sets, [:metadata, :rank])
  end

  def down do
    drop_dependency_trigger(:ingest_sheets, :works)
    drop_dependency_trigger(:collections, :works)
    drop_dependency_trigger(:works, :file_sets)
    drop_dependency_trigger(:works, :collections)

    drop_parent_trigger(:works, :file_sets)
  end

  defp create_dependency_trigger(parent, child, fields) do
    create_dependency_trigger(parent, child, fields, parent)
  end

  defp create_dependency_trigger(parent, child, fields, column_name) do
    with {function_name, trigger_name} <- object_names(parent, child) do
      condition =
        fields
        |> Enum.flat_map(
          &[
            "(NEW.#{&1} <> OLD.#{&1})",
            "(NEW.#{&1} IS NULL AND OLD.#{&1} IS NOT NULL)",
            "(NEW.#{&1} IS NOT NULL AND OLD.#{&1} IS NULL)"
          ]
        )
        |> Enum.join(" OR ")

      execute """
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

      execute """
      CREATE TRIGGER #{trigger_name}
        AFTER UPDATE
        ON #{parent}
        FOR EACH ROW
        EXECUTE PROCEDURE #{function_name}()
      """
    end
  end

  defp create_parent_trigger(parent, child, fields) do
    with {function_name, trigger_name} <- object_names_for_parent_trigger(parent, child) do
      condition =
        fields
        |> Enum.flat_map(
          &[
            "(NEW.#{&1} <> OLD.#{&1})",
            "(NEW.#{&1} IS NULL AND OLD.#{&1} IS NOT NULL)",
            "(NEW.#{&1} IS NOT NULL AND OLD.#{&1} IS NULL)"
          ]
        )
        |> Enum.join(" OR ")

      execute """
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

      execute """
      CREATE TRIGGER #{trigger_name}
        AFTER UPDATE
        ON #{child}
        FOR EACH ROW
        EXECUTE PROCEDURE #{function_name}()
      """
    end
  end

  defp drop_dependency_trigger(parent, child) do
    with {function_name, trigger_name} <- object_names(parent, child) do
      execute("DROP TRIGGER IF EXISTS #{trigger_name} ON #{parent};")
      execute("DROP FUNCTION IF EXISTS #{function_name};")
    end
  end

  defp drop_parent_trigger(parent, child) do
    with {function_name, trigger_name} <- object_names_for_parent_trigger(parent, child) do
      execute("DROP TRIGGER IF EXISTS #{trigger_name} ON #{child};")
      execute("DROP FUNCTION IF EXISTS #{function_name};")
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
