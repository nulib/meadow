defmodule Meadow.Repo.Migrations.CodedTermsToTextColumns do
  @moduledoc """
  Store top-level coded term columns (works.visibility, works.work_type,
  works.behavior, collections.visibility, file_sets.role) as the bare term id
  (text) instead of a `{"id": ..., "scheme": ...}` jsonb object. The scheme is
  fixed per column and now lives in the Ecto schema declaration.
  """

  use Ecto.Migration

  @columns [
    {:works, :visibility},
    {:works, :work_type},
    {:works, :behavior},
    {:collections, :visibility},
    {:file_sets, :role}
  ]

  @published_tables ~w(works collections file_sets)

  def up do
    # Keep the bulk rewrite out of the WAL event stream (see Meadow.Events.Indexing)
    execute("ALTER PUBLICATION events DROP TABLE #{Enum.join(@published_tables, ", ")}")

    Enum.each(@columns, fn {table, column} ->
      tmp = :"#{column}_id_tmp"

      alter table(table) do
        add(tmp, :text)
      end

      execute("UPDATE #{table} SET #{tmp} = #{column}->>'id'")

      alter table(table) do
        remove(column)
      end

      rename(table(table), tmp, to: column)
      create(index(table, [column]))
    end)

    execute("ALTER PUBLICATION events ADD TABLE #{Enum.join(@published_tables, ", ")}")
  end

  def down do
    execute("ALTER PUBLICATION events DROP TABLE #{Enum.join(@published_tables, ", ")}")

    Enum.each(@columns, fn {table, column} ->
      tmp = :"#{column}_map_tmp"
      scheme = scheme_for(table, column)

      alter table(table) do
        add(tmp, :map)
      end

      execute("""
      UPDATE #{table}
         SET #{tmp} = jsonb_build_object('id', #{column}, 'scheme', '#{scheme}')
       WHERE #{column} IS NOT NULL
      """)

      drop(index(table, [column]))

      alter table(table) do
        remove(column)
      end

      rename(table(table), tmp, to: column)
    end)

    execute("ALTER PUBLICATION events ADD TABLE #{Enum.join(@published_tables, ", ")}")
  end

  defp scheme_for(:file_sets, :role), do: "file_set_role"
  defp scheme_for(_table, column), do: to_string(column)
end
