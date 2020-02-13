defmodule Meadow.Repo.Migrations.TouchWorksOnCollectionUpdate do
  use Ecto.Migration

  def up do
    create_dependency_trigger(:collections, :works, [:name])
    create_dependency_trigger(:works, :file_sets, [:published, :visibility])
  end

  def down do
    drop_dependency_trigger(:collections, :works)
    drop_dependency_trigger(:works, :file_sets)
  end

  defp create_dependency_trigger(parent, child, fields) do
    with {function_name, trigger_name} <- object_names(parent, child) do
      condition = fields |> Enum.map(&"NEW.#{&1} <> OLD.#{&1}") |> Enum.join(" OR ")

      execute """
      CREATE OR REPLACE FUNCTION #{function_name}()
        RETURNS trigger AS $$
      BEGIN
        IF #{condition} THEN
          UPDATE #{child}
          SET updated_at = NOW()
          WHERE #{Inflex.singularize(parent)}_id = NEW.id;
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

  defp drop_dependency_trigger(parent, child) do
    with {function_name, trigger_name} <- object_names(parent, child) do
      execute("DROP TRIGGER #{trigger_name};")
      execute("DROP FUNCTION #{function_name};")
    end
  end

  defp object_names(parent, child) do
    {
      "reindex_#{child}_when_#{parent}_changes",
      "#{parent}_#{child}_reindex"
    }
  end
end
